require 'rails_helper'

RSpec.describe Voice, type: :model do
  let(:user) { create(:user) }

  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:voice_id) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:language) }

    describe 'voice_id uniqueness' do
      let!(:existing_voice) { create(:voice, user: user, voice_id: 'unique_voice_id') }

      it 'validates uniqueness of voice_id scoped to user' do
        duplicate_voice = build(:voice, user: user, voice_id: 'unique_voice_id')
        expect(duplicate_voice).to be_invalid
        expect(duplicate_voice.errors[:voice_id]).to include('has already been taken')
      end

      it 'allows same voice_id for different users' do
        other_user = create(:user)
        voice = build(:voice, user: other_user, voice_id: 'unique_voice_id')
        expect(voice).to be_valid
      end
    end

    describe 'gender validation' do
      it 'allows valid gender values' do
        %w[male female unknown].each do |gender|
          voice = build(:voice, user: user, gender: gender)
          expect(voice).to be_valid
        end
      end

      it 'allows blank gender' do
        voice = build(:voice, user: user, gender: nil)
        expect(voice).to be_valid
      end

      it 'rejects invalid gender values' do
        voice = build(:voice, user: user, gender: 'invalid')
        expect(voice).to be_invalid
        expect(voice.errors[:gender]).to include('is not included in the list')
      end
    end
  end

  describe 'scopes' do
    let!(:active_voice) { create(:voice, user: user, active: true) }
    let!(:inactive_voice) { create(:voice, user: user, active: false) }
    let!(:english_voice) { create(:voice, user: user, language: 'English') }
    let!(:spanish_voice) { create(:voice, :spanish, user: user) }
    let!(:female_voice) { create(:voice, :female, user: user) }
    let!(:male_voice) { create(:voice, :male, user: user) }
    let!(:pause_supporting_voice) { create(:voice, user: user, support_pause: true) }
    let!(:emotion_voice) { create(:voice, :with_emotion_support, user: user) }
    let!(:interactive_voice) { create(:voice, :interactive_avatar_compatible, user: user) }

    describe '.active' do
      it 'returns only active voices' do
        expect(Voice.active).to include(active_voice)
        expect(Voice.active).not_to include(inactive_voice)
      end
    end

    describe '.by_language' do
      it 'returns voices with specified language' do
        expect(Voice.by_language('English')).to include(english_voice)
        expect(Voice.by_language('English')).not_to include(spanish_voice)
      end
    end

    describe '.by_gender' do
      it 'returns voices with specified gender' do
        expect(Voice.by_gender('female')).to include(female_voice)
        expect(Voice.by_gender('female')).not_to include(male_voice)
      end
    end

    describe '.supporting_pause' do
      it 'returns voices that support pause' do
        expect(Voice.supporting_pause).to include(pause_supporting_voice)
      end
    end

    describe '.with_emotion_support' do
      it 'returns voices with emotion support' do
        expect(Voice.with_emotion_support).to include(emotion_voice)
      end
    end

    describe '.for_interactive_avatar' do
      it 'returns voices compatible with interactive avatars' do
        expect(Voice.for_interactive_avatar).to include(interactive_voice)
      end
    end
  end

  describe '.sync_for_user' do
    let(:voices_data) do
      [
        {
          voice_id: "ea8cc4c6a0d4487782f0ccb8de7d4dd0",
          language: "English",
          gender: "unknown",
          name: "mary_en_3",
          preview_audio: nil,
          support_pause: true,
          emotion_support: false,
          support_interactive_avatar: false,
          support_locale: false
        },
        {
          voice_id: "fb8cc4c6a0d4487782f0ccb8de7d4dd1",
          language: "Spanish",
          gender: "female",
          name: "sofia_es_1",
          preview_audio: "https://example.com/sofia.mp3",
          support_pause: false,
          emotion_support: true,
          support_interactive_avatar: true,
          support_locale: true
        }
      ]
    end

    it 'creates new voices from API data' do
      expect { Voice.sync_for_user(user, voices_data) }
        .to change { user.voices.count }.by(2)
    end

    it 'updates existing voices with new data' do
      existing_voice = create(:voice, user: user, voice_id: voices_data.first[:voice_id], name: 'Old Name')

      Voice.sync_for_user(user, voices_data)

      existing_voice.reload
      expect(existing_voice.name).to eq('mary_en_3')
      expect(existing_voice.language).to eq('English')
      expect(existing_voice.active).to be true
    end

    it 'marks old voices as inactive' do
      old_voice = create(:voice, user: user, voice_id: 'old_voice_id', active: true)

      Voice.sync_for_user(user, voices_data)

      old_voice.reload
      expect(old_voice.active).to be false
    end

    it 'performs sync operations atomically' do
      # Test that all changes happen together or not at all
      allow(user.voices).to receive(:update_all).and_raise(StandardError, 'Test error')

      expect { Voice.sync_for_user(user, voices_data) }.to raise_error(StandardError)
      # Verify no partial changes were made
      expect(user.voices.count).to eq(0)
    end

    it 'sets correct attributes for each voice' do
      Voice.sync_for_user(user, voices_data)

      voice = user.voices.find_by(voice_id: voices_data.first[:voice_id])
      expect(voice.language).to eq('English')
      expect(voice.gender).to eq('unknown')
      expect(voice.name).to eq('mary_en_3')
      expect(voice.preview_audio).to be_nil
      expect(voice.support_pause).to be true
      expect(voice.emotion_support).to be false
      expect(voice.active).to be true
    end
  end

  describe '#display_name' do
    it 'includes name and language' do
      voice = build(:voice, name: 'John', language: 'English', gender: nil)
      expect(voice.display_name).to eq('John (English)')
    end

    it 'includes gender when present' do
      voice = build(:voice, name: 'Sofia', language: 'Spanish', gender: 'female')
      expect(voice.display_name).to eq('Sofia (Spanish, female)')
    end

    it 'handles unknown gender' do
      voice = build(:voice, name: 'Alex', language: 'French', gender: 'unknown')
      expect(voice.display_name).to eq('Alex (French, unknown)')
    end
  end

  describe '#supports_feature?' do
    let(:full_featured_voice) { create(:voice, :full_featured, user: user) }
    let(:basic_voice) { create(:voice, user: user, support_pause: false, emotion_support: false) }

    it 'returns true for supported features' do
      expect(full_featured_voice.supports_feature?(:pause)).to be true
      expect(full_featured_voice.supports_feature?('emotion')).to be true
      expect(full_featured_voice.supports_feature?(:interactive_avatar)).to be true
      expect(full_featured_voice.supports_feature?(:locale)).to be true
    end

    it 'returns false for unsupported features' do
      expect(basic_voice.supports_feature?(:pause)).to be false
      expect(basic_voice.supports_feature?(:emotion)).to be false
      expect(basic_voice.supports_feature?(:interactive_avatar)).to be false
      expect(basic_voice.supports_feature?(:locale)).to be false
    end

    it 'returns false for unknown features' do
      expect(full_featured_voice.supports_feature?(:unknown_feature)).to be false
    end
  end

  describe 'factory' do
    it 'creates a valid voice' do
      voice = create(:voice, user: user)
      expect(voice).to be_persisted
      expect(voice.user).to eq(user)
      expect(voice.voice_id).to be_present
      expect(voice.name).to be_present
      expect(voice.language).to eq('English')
      expect(voice.active).to be true
    end

    it 'creates valid voices with traits' do
      female_voice = create(:voice, :female, :with_emotion_support, user: user)
      expect(female_voice.gender).to eq('female')
      expect(female_voice.emotion_support).to be true
    end
  end
end
