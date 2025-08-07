require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Heygen::ListAvatarsService, type: :service do
  let(:user) { create(:user) }

  before do
    # Stub Heygen validation endpoint called during token creation
    stub_request(:get, "https://api.heygen.com/v2/avatars")
      .to_return(status: 200, body: '{"data": []}')
  end

  let!(:api_token) do
    token = build(:api_token, user: user, provider: 'heygen', is_valid: true)
    token.save(validate: false)
    token
  end

  subject { described_class.new(user) }

  describe '#call' do
    context 'when user has valid API token' do
      let(:mock_response) do
        {
          'data' => {
            'avatars' => [
              {
                'avatar_id' => 'avatar_1',
                'avatar_name' => 'Sarah',
                'preview_image_url' => 'https://example.com/sarah.jpg',
                'gender' => 'female',
                'is_public' => true
              },
              {
                'avatar_id' => 'avatar_2',
                'avatar_name' => 'John',
                'preview_image_url' => 'https://example.com/john.jpg',
                'gender' => 'male',
                'is_public' => false
              }
            ]
          }
        }
      end

      before do
        allow(Heygen::ListAvatarsService).to receive(:get).and_return(
          double(success?: true, body: mock_response.to_json)
        )
      end

      it 'returns successful result with avatars data' do
        result = subject.call

        expect(result[:success]).to be true
        expect(result[:data]).to be_an(Array)
        expect(result[:data].length).to eq(2)

        avatar = result[:data].first
        expect(avatar[:id]).to eq('avatar_1')
        expect(avatar[:name]).to eq('Sarah')
        expect(avatar[:gender]).to eq('female')
        expect(avatar[:is_public]).to be true
      end

      it 'caches the result' do
        cache_key = "heygen_avatars_#{user.id}_#{api_token.mode}"

        expect(Rails.cache).to receive(:read).with(cache_key).and_return(nil)
        expect(Rails.cache).to receive(:write).with(cache_key, anything, expires_in: 18.hours)

        subject.call
      end

      it 'returns cached result if available' do
        cached_data = [ { id: 'cached_avatar', name: 'Cached' } ]
        cache_key = "heygen_avatars_#{user.id}_#{api_token.mode}"

        expect(Rails.cache).to receive(:read).with(cache_key).and_return(cached_data)
        expect(Heygen::ListAvatarsService).not_to receive(:get)

        result = subject.call
        expect(result[:success]).to be true
        expect(result[:data]).to eq(cached_data)
      end

      it 'makes API call with correct headers' do
        expect(Heygen::ListAvatarsService).to receive(:get).with(
          '/v2/avatars',
          {
            headers: {
              'X-API-KEY' => api_token.encrypted_token,
              'Content-Type' => 'application/json'
            },
            query: {}
          }
        ).and_return(double(success?: true, body: mock_response.to_json))

        subject.call
      end
    end

    context 'when API call fails' do
      before do
        allow(Heygen::ListAvatarsService).to receive(:get).and_return(
          double(success?: false, message: 'API Error')
        )
      end

      it 'returns failure result' do
        result = subject.call

        expect(result[:success]).to be false
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
        allow(Heygen::ListAvatarsService).to receive(:get).and_raise(StandardError, 'Network error')
      end

      it 'returns failure result with error message' do
        result = subject.call

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Error fetching avatars: Network error')
      end
    end
  end
end
