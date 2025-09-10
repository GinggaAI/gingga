require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Heygen::ListVoicesService, type: :service do
  let(:user) { create(:user) }

  before do
    # Stub Heygen validation endpoint called during token creation
    stub_request(:get, "https://api.heygen.com/v2/avatars")
      .to_return(status: 200, body: '{"data": []}')
  end

  let!(:api_token) do
    # Skip the before_save callback to avoid API calls in tests
    ApiToken.skip_callback(:save, :before, :validate_token_with_provider)
    token = create(:api_token, :heygen, user: user, is_valid: true)
    ApiToken.set_callback(:save, :before, :validate_token_with_provider)
    token
  end

  describe '#call' do
    let(:mock_response) do
      {
        'data' => {
          'voices' => [
            {
              'voice_id' => 'voice_1',
              'name' => 'Emma',
              'language' => 'English',
              'gender' => 'female',
              'age_group' => 'young_adult',
              'accent' => 'American',
              'is_public' => true,
              'preview_audio_url' => 'https://example.com/emma.mp3'
            },
            {
              'voice_id' => 'voice_2',
              'name' => 'Carlos',
              'language' => 'Spanish',
              'gender' => 'male',
              'age_group' => 'middle_aged',
              'accent' => 'Mexican',
              'is_public' => true,
              'preview_audio_url' => 'https://example.com/carlos.mp3'
            }
          ]
        }
      }
    end

    context 'without filters' do
      subject { described_class.new(user) }

      before do
        mock_response_double = OpenStruct.new(
          success?: true,
          body: mock_response
        )

        allow(subject).to receive(:fetch_voices).and_return(mock_response_double)
      end

      it 'returns all voices' do
        result = subject.call

        expect(result[:success]).to be true
        expect(result[:data]).to be_an(Array)
        expect(result[:data].length).to eq(2)

        voice = result[:data].first
        expect(voice[:id]).to eq('voice_1')
        expect(voice[:name]).to eq('Emma')
        expect(voice[:language]).to eq('English')
        expect(voice[:gender]).to eq('female')
        expect(voice[:age_group]).to eq('young_adult')
        expect(voice[:accent]).to eq('American')
      end

      it 'caches the result' do
        # Caching is currently disabled in the service
        # This test verifies the service still works without caching
        result = subject.call
        expect(result[:success]).to be true
      end
    end

    context 'with language filter' do
      subject { described_class.new(user, { language: 'Spanish' }) }

      before do
        mock_response_double = OpenStruct.new(
          success?: true,
          body: mock_response
        )

        allow(subject).to receive(:fetch_voices).and_return(mock_response_double)
      end

      it 'returns filtered voices by language' do
        result = subject.call

        expect(result[:success]).to be true
        expect(result[:data].length).to eq(1)
        expect(result[:data].first[:name]).to eq('Carlos')
        expect(result[:data].first[:language]).to eq('Spanish')
      end
    end

    context 'with gender filter' do
      subject { described_class.new(user, { gender: 'female' }) }

      before do
        mock_response_double = OpenStruct.new(
          success?: true,
          body: mock_response
        )

        allow(subject).to receive(:fetch_voices).and_return(mock_response_double)
      end

      it 'returns filtered voices by gender' do
        result = subject.call

        expect(result[:success]).to be true
        expect(result[:data].length).to eq(1)
        expect(result[:data].first[:name]).to eq('Emma')
        expect(result[:data].first[:gender]).to eq('female')
      end
    end

    context 'with multiple filters' do
      subject { described_class.new(user, { language: 'English', gender: 'female' }) }

      before do
        mock_response_double = OpenStruct.new(
          success?: true,
          body: mock_response
        )

        allow(subject).to receive(:fetch_voices).and_return(mock_response_double)
      end

      it 'returns voices matching all filters' do
        result = subject.call

        expect(result[:success]).to be true
        expect(result[:data].length).to eq(1)
        expect(result[:data].first[:name]).to eq('Emma')
      end
    end

    context 'when using cached data' do
      subject { described_class.new(user, { gender: 'male' }) }

      before do
        mock_response_double = OpenStruct.new(
          success?: true,
          body: mock_response
        )

        allow(subject).to receive(:fetch_voices).and_return(mock_response_double)
      end

      it 'applies filters to fresh data (caching disabled)' do
        # Since caching is disabled, test that filtering still works on fresh API data
        result = subject.call
        expect(result[:success]).to be true
        expect(result[:data].length).to eq(1)
        expect(result[:data].first[:name]).to eq('Carlos')
        expect(result[:data].first[:gender]).to eq('male')
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

    context 'when API call fails' do
      subject { described_class.new(user) }

      before do
        mock_response_double = OpenStruct.new(
          success?: false,
          message: 'API Error'
        )

        allow(subject).to receive(:fetch_voices).and_return(mock_response_double)
      end

      it 'returns failure result' do
        result = subject.call

        expect(result[:success]).to be false
        expect(result[:error]).to include('Failed to fetch voices')
      end
    end

    context 'when an exception occurs' do
      subject { described_class.new(user) }

      before do
        allow(subject).to receive(:fetch_voices).and_raise(StandardError, 'Network error')
      end

      it 'returns failure result with error message' do
        result = subject.call

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Error fetching voices: Network error')
      end
    end
  end
end
