require 'rails_helper'

RSpec.describe Heygen::ListAvatarsService, type: :service do
  let(:user) { create(:user) }
  let!(:api_token) do
    # Skip the before_save callback to avoid API calls in tests
    ApiToken.skip_callback(:save, :before, :validate_token_with_provider)
    token = create(:api_token, :heygen, user: user, is_valid: true)
    ApiToken.set_callback(:save, :before, :validate_token_with_provider)
    token
  end

  subject { described_class.new(user) }

  describe '#call' do
    context 'when user has valid API token', :vcr do
      before do
        allow(subject).to receive(:api_token_present?).and_return(true)

        # Ensure @api_token is available for cache_key_for method
        allow(subject.instance_variable_get(:@api_token) || api_token).to receive(:mode).and_return('production')
        subject.instance_variable_set(:@api_token, api_token)

        # Mock successful HTTP response using VCR data structure
        mock_body = {
          'data' => {
            'avatars' => [
              {
                'avatar_id' => 'test_avatar_1',
                'avatar_name' => 'Test Avatar',
                'preview_image_url' => 'https://example.com/avatar.jpg',
                'gender' => 'female',
                'is_public' => true
              }
            ]
          }
        }

        mock_response = OpenStruct.new(
          success?: true,
          body: mock_body
        )

        # Mock parse_json to return the body directly since it's already parsed
        allow(subject).to receive(:parse_json).and_return(mock_body)

        allow(subject).to receive(:fetch_avatars).and_return(mock_response)
      end

      it 'returns successful result with avatars data' do
        result = subject.call

        expect(result[:success]).to be true
        expect(result[:data]).to be_an(Array)
        expect(result[:data].length).to eq(1)

        avatar = result[:data].first
        expect(avatar[:id]).to eq('test_avatar_1')
        expect(avatar[:name]).to eq('Test Avatar')
        expect(avatar[:gender]).to eq('female')
        expect(avatar[:is_public]).to be true
      end

      it 'caches the result' do
        cache_key = "heygen_avatars_#{user.id}_#{api_token.mode}"

        # Clear cache to ensure fresh request
        Rails.cache.delete(cache_key)

        expect(Rails.cache).to receive(:write).with(cache_key, anything, expires_in: 18.hours)

        subject.call
      end

      it 'returns cached result if available' do
        cached_data = [ { id: 'cached_avatar', name: 'Cached' } ]
        cache_key = "heygen_avatars_#{user.id}_#{api_token.mode}"

        # Mock cache read to return cached data
        allow(Rails.cache).to receive(:read).with(cache_key).and_return(cached_data)

        result = subject.call
        expect(result[:success]).to be true
        expect(result[:data]).to eq(cached_data)
      end
    end

    context 'when API call fails', :vcr do
      before do
        allow(subject).to receive(:api_token_present?).and_return(true)

        # Ensure @api_token is available for cache_key_for method
        subject.instance_variable_set(:@api_token, api_token)

        # Mock failed HTTP response
        mock_response = OpenStruct.new(
          success?: false,
          message: 'Unauthorized'
        )

        allow(subject).to receive(:fetch_avatars).and_return(mock_response)
      end

      it 'returns failure result' do
        result = subject.call

        expect(result[:success]).to be false
        expect(result[:error]).to be_present
        expect(result[:error]).to include('Failed to fetch avatars')
      end
    end

    context 'when user has no valid API token' do
      let(:user_without_token) { create(:user) }
      subject { described_class.new(user_without_token) }

      it 'returns failure result' do
        result = subject.call

        expect(result[:success]).to be false
        expect(result[:error]).to eq('No valid Heygen API token found')
      end
    end

    context 'when an exception occurs' do
      before do
        allow(subject).to receive(:api_token_present?).and_return(true)
        subject.instance_variable_set(:@api_token, api_token)
        allow(subject).to receive(:fetch_avatars).and_raise(StandardError, 'Network error')
      end

      it 'returns failure result with error message' do
        result = subject.call

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Error fetching avatars: Network error')
      end
    end
  end
end
