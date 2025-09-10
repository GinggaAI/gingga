require 'rails_helper'

RSpec.describe Heygen::SynchronizeVoicesService, type: :service do
  let(:user) { create(:user) }
  let!(:api_token) do
    # Skip the before_save callback to avoid API calls in tests
    ApiToken.skip_callback(:save, :before, :validate_token_with_provider)
    token = create(:api_token, :heygen, user: user, is_valid: true)
    ApiToken.set_callback(:save, :before, :validate_token_with_provider)
    token
  end
  let(:service) { described_class.new(user: user) }
  let(:service_with_limit) { described_class.new(user: user, voices_count: 2) }

  describe '#call' do
    context 'with valid API token and successful response' do
      before do
        # Mock successful voices response (format matches ListVoicesService output)
        # ListVoicesService now filters out voices with preview_audio_url, so mock only includes filtered voices
        mock_voices_data = [
          {
            id: 'ea8cc4c6a0d4487782f0ccb8de7d4dd0',
            language: 'English',
            gender: 'unknown',
            name: 'mary_en_3',
            preview_audio_url: nil,
            age_group: nil,
            accent: nil,
            is_public: true
          },
          {
            id: 'gc8cc4c6a0d4487782f0ccb8de7d4dd2',
            language: 'English',
            gender: 'male',
            name: 'john_en_1',
            preview_audio_url: nil,
            age_group: nil,
            accent: nil,
            is_public: false
          },
          {
            id: 'hc8cc4c6a0d4487782f0ccb8de7d4dd3',
            language: 'French',
            gender: 'female',
            name: 'marie_fr_1',
            preview_audio_url: nil,
            age_group: nil,
            accent: nil,
            is_public: true
          }
        ]

        mock_list_result = {
          success: true,
          data: mock_voices_data
        }

        allow_any_instance_of(Heygen::ListVoicesService).to receive(:call).and_return(mock_list_result)
      end

      it 'synchronizes only voices with null preview_audio_url' do
        result = service.call

        expect(result.success?).to be true
        expect(result.data[:total_fetched]).to eq(3) # Total voices in mock data (already filtered by ListVoicesService)
        expect(result.data[:synchronized_count]).to eq(3) # Successfully synchronized
      end

      it 'creates Voice records with correct attributes' do
        expect { service.call }.to change { user.voices.count }.by(3)

        mary_voice = user.voices.find_by(voice_id: 'ea8cc4c6a0d4487782f0ccb8de7d4dd0')
        expect(mary_voice).to be_present
        expect(mary_voice.name).to eq('mary_en_3')
        expect(mary_voice.language).to eq('English')
        expect(mary_voice.gender).to eq('unknown')
        expect(mary_voice.preview_audio).to be_nil
        expect(mary_voice.active).to be true

        john_voice = user.voices.find_by(voice_id: 'gc8cc4c6a0d4487782f0ccb8de7d4dd2')
        expect(john_voice).to be_present
        expect(john_voice.name).to eq('john_en_1')
        expect(john_voice.language).to eq('English')
        expect(john_voice.gender).to eq('male')

        marie_voice = user.voices.find_by(voice_id: 'hc8cc4c6a0d4487782f0ccb8de7d4dd3')
        expect(marie_voice).to be_present
        expect(marie_voice.name).to eq('marie_fr_1')
        expect(marie_voice.language).to eq('French')
        expect(marie_voice.gender).to eq('female')
        expect(marie_voice.preview_audio).to be_nil
      end

      it 'updates existing voices with new data' do
        # Create an existing voice
        existing_voice = create(:voice,
          user: user,
          voice_id: 'ea8cc4c6a0d4487782f0ccb8de7d4dd0',
          name: 'Old Mary',
          language: 'French'
        )

        service.call

        existing_voice.reload
        expect(existing_voice.name).to eq('mary_en_3')
        expect(existing_voice.language).to eq('English')
        expect(existing_voice.gender).to eq('unknown')
        expect(existing_voice.active).to be true
      end

      it 'sets default support flags' do
        service.call

        voice = user.voices.find_by(voice_id: 'ea8cc4c6a0d4487782f0ccb8de7d4dd0')
        expect(voice.support_pause).to be true
        expect(voice.emotion_support).to be false
        expect(voice.support_interactive_avatar).to be false
        expect(voice.support_locale).to be false
      end

      it 'respects voices_count limit when specified' do
        # Expect ListVoicesService to be called with voices_count parameter
        expect(Heygen::ListVoicesService).to receive(:new)
          .with(user, {}, voices_count: 2).and_call_original

        service_with_limit.call
      end
    end

    context 'with API error response' do
      before do
        mock_error_result = {
          success: false,
          error: 'API request failed: Unauthorized'
        }

        allow_any_instance_of(Heygen::ListVoicesService).to receive(:call).and_return(mock_error_result)
      end

      it 'returns failure result when ListVoicesService fails' do
        result = service.call

        expect(result.success?).to be false
        expect(result.error).to include('Failed to fetch voices from HeyGen')
      end
    end

    context 'when voice save fails' do
      before do
        # Mock successful voices response first (format matches ListVoicesService output)
        mock_voices_data = [
          {
            id: 'ea8cc4c6a0d4487782f0ccb8de7d4dd0',
            language: 'English',
            gender: 'unknown',
            name: 'mary_en_3',
            preview_audio_url: nil,
            age_group: nil,
            accent: nil,
            is_public: true
          }
        ]

        mock_list_result = {
          success: true,
          data: mock_voices_data
        }

        allow_any_instance_of(Heygen::ListVoicesService).to receive(:call).and_return(mock_list_result)

        # Then mock voice save failure
        allow_any_instance_of(Voice).to receive(:save).and_return(false)
        allow_any_instance_of(Voice).to receive(:errors).and_return(
          double(full_messages: [ 'Name is invalid' ])
        )
      end

      it 'logs error and continues with other voices' do
        expect(Rails.logger).to receive(:error).with(/Failed to sync voice/).at_least(:once)

        result = service.call

        expect(result.success?).to be true
        expect(result.data[:synchronized_count]).to eq(0) # No voices saved due to errors
      end
    end

    context 'when an exception occurs' do
      before do
        allow_any_instance_of(Heygen::ListVoicesService).to receive(:call)
          .and_raise(StandardError, 'Network error')
      end

      it 'returns failure result with error message' do
        result = service.call

        expect(result.success?).to be false
        expect(result.error).to eq('Error synchronizing voices: Network error')
      end
    end
  end

  describe 'private methods' do
    describe '#build_raw_response' do
      it 'builds properly formatted JSON response' do
        voices_data = [ { id: 'test', name: 'Test Voice' } ]
        raw_response = service.send(:build_raw_response, voices_data)

        parsed_response = JSON.parse(raw_response)
        expect(parsed_response['code']).to eq(100)
        expect(parsed_response['data']['voices']).to eq([ { 'id' => 'test', 'name' => 'Test Voice' } ])
      end
    end

    describe '#sync_voice' do
      let(:voice_data) do
        {
          id: 'test_voice_id',
          name: 'Test Voice',
          language: 'English',
          gender: 'female',
          preview_audio_url: nil
        }
      end

      it 'creates new voice with correct attributes' do
        raw_response = '{"test": "response"}'

        voice = service.send(:sync_voice, voice_data, raw_response)

        expect(voice).to be_persisted
        expect(voice.voice_id).to eq('test_voice_id')
        expect(voice.name).to eq('Test Voice')
        expect(voice.language).to eq('English')
        expect(voice.gender).to eq('female')
        expect(voice.preview_audio).to be_nil
        expect(voice.active).to be true
      end

      it 'returns nil when save fails' do
        allow_any_instance_of(Voice).to receive(:save).and_return(false)
        allow_any_instance_of(Voice).to receive(:errors).and_return(
          double(full_messages: [ 'Invalid' ])
        )

        voice = service.send(:sync_voice, voice_data, '{}')
        expect(voice).to be_nil
      end
    end
  end
end
