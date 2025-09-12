require 'rails_helper'

RSpec.describe Reels::ScenesPreloadService do
  let(:user) { create(:user) }
  let(:reel) { create(:reel, user: user) }
  let(:scenes_data) do
    [
      { "voiceover" => "First scene script", "avatar_id" => "custom_avatar_001" },
      { "script" => "Second scene script" },
      { "description" => "Third scene description" },
      { "voiceover" => "" } # This should be skipped
    ]
  end

  subject(:service) do
    described_class.new(
      reel: reel,
      scenes: scenes_data,
      current_user: user
    )
  end

  describe '#call' do
    before do
      # Create some existing scenes that should be cleared
      create(:reel_scene, reel: reel)
      create(:reel_scene, reel: reel)
    end

    after do
      # Clean up any avatars/voices created during tests to prevent interference
      user.avatars.destroy_all
      user.voices.destroy_all
    end

    context 'with valid scenes data' do
      before do
        # Ensure clean state for each test
        user.avatars.destroy_all
        user.voices.destroy_all
      end

      it 'clears existing scenes and creates new ones' do
        expect { service.call }.to change { reel.reel_scenes.count }.from(2).to(3)
      end

      it 'creates scenes with correct data' do
        service.call
        reel.reload

        scenes = reel.reel_scenes.order(:scene_number)
        expect(scenes[0].script).to eq("First scene script")
        expect(scenes[0].avatar_id).to eq("custom_avatar_001")
        expect(scenes[1].script).to eq("Second scene script")
        expect(scenes[2].script).to eq("Third scene description")
      end

      it 'uses default avatar and voice for scenes without specific IDs' do
        service.call
        reel.reload

        second_scene = reel.reel_scenes.find_by(scene_number: 2)
        expect(second_scene.avatar_id).to eq("avatar_001") # default
        expect(second_scene.voice_id).to eq("voice_001") # default
      end

      it 'returns successful result with counts' do
        result = service.call

        expect(result.success?).to be true
        expect(result.data[:created_scenes]).to eq(3)
        expect(result.data[:total_scenes]).to eq(4)
      end
    end

    context 'with user avatars and voices' do
      it 'uses user avatars and voices as defaults' do
        # Create user's avatars and voices within the test
        user_avatar = create(:avatar, user: user, avatar_id: "user_avatar_123", status: "active")
        user_voice = create(:voice, user: user, voice_id: "user_voice_123", active: true)

        service.call
        reel.reload

        second_scene = reel.reel_scenes.find_by(scene_number: 2)
        expect(second_scene.avatar_id).to eq("user_avatar_123")
        expect(second_scene.voice_id).to eq("user_voice_123")
      end
    end

    context 'when reel is not persisted' do
      let(:unpersisted_reel) { build(:reel, user: user) }
      let(:service_with_unpersisted_reel) do
        described_class.new(
          reel: unpersisted_reel,
          scenes: scenes_data,
          current_user: user
        )
      end

      it 'saves the reel before processing' do
        expect(unpersisted_reel).not_to be_persisted

        result = service_with_unpersisted_reel.call

        expect(unpersisted_reel).to be_persisted
        expect(result.success?).to be true
      end
    end

    context 'with reel requiring scenes' do
      let(:scene_requiring_reel) { create(:reel, user: user, template: 'avatar_and_video') }
      let(:service_with_scene_reel) do
        described_class.new(
          reel: scene_requiring_reel,
          scenes: [ { "voiceover" => "Only one scene" } ],
          current_user: user
        )
      end

      before do
        allow(scene_requiring_reel).to receive(:requires_scenes?).and_return(true)
      end

      it 'fills with default scenes when less than 3 provided' do
        result = service_with_scene_reel.call
        scene_requiring_reel.reload

        expect(scene_requiring_reel.reel_scenes.count).to eq(3)
        expect(result.success?).to be true
        expect(result.data[:created_scenes]).to eq(3)

        # Check that default scenes were added
        scenes = scene_requiring_reel.reel_scenes.order(:scene_number)
        expect(scenes[0].script).to eq("Only one scene")
        expect(scenes[1].script).to include("Default scene 2 content")
        expect(scenes[2].script).to include("Default scene 3 content")
      end

      it 'limits to 3 scenes for scene-requiring templates' do
        many_scenes = (1..5).map { |i| { "voiceover" => "Scene #{i}" } }
        service_many_scenes = described_class.new(
          reel: scene_requiring_reel,
          scenes: many_scenes,
          current_user: user
        )

        result = service_many_scenes.call
        scene_requiring_reel.reload

        expect(scene_requiring_reel.reel_scenes.count).to eq(3)
        expect(result.success?).to be true
      end
    end

    context 'with invalid scene data' do
      let(:invalid_scenes) do
        [
          { "voiceover" => "Valid scene" },
          { "voiceover" => "" }, # Empty script
          { "voiceover" => "   " }, # Whitespace only
          { "description" => nil }, # Nil content
          {} # No script fields
        ]
      end

      let(:service_with_invalid) do
        described_class.new(
          reel: reel,
          scenes: invalid_scenes,
          current_user: user
        )
      end

      it 'only creates scenes with valid data' do
        # Allow the service to add default scenes if the reel requires them
        allow(reel).to receive(:requires_scenes?).and_return(false)

        result = service_with_invalid.call
        reel.reload

        expect(reel.reel_scenes.count).to eq(1) # Only the valid scene
        expect(result.success?).to be true
        expect(result.data[:created_scenes]).to eq(1)
        expect(result.data[:total_scenes]).to eq(5)
      end
    end

    context 'when avatar or voice defaults are blank' do
      let(:service_with_blanks) do
        described_class.new(
          reel: reel,
          scenes: [ { "voiceover" => "Test scene" } ],
          current_user: user
        )
      end

      before do
        # Mock avatars and voices to return records with blank avatar_id/voice_id
        avatar = double('Avatar', avatar_id: "", voice_id: nil)
        voice = double('Voice', voice_id: "", avatar_id: nil)

        allow(user.avatars.active).to receive(:first).and_return(avatar)
        allow(user.voices.active).to receive(:first).and_return(voice)
        allow(user.avatars).to receive(:first).and_return(avatar)
        allow(user.voices).to receive(:first).and_return(voice)
      end

      it 'falls back to system defaults for blank IDs' do
        result = service_with_blanks.call
        reel.reload

        scene = reel.reel_scenes.first
        expect(scene.avatar_id).to eq("avatar_001")
        expect(scene.voice_id).to eq("voice_001")
      end
    end

    context 'when scene creation fails' do
      before do
        allow(reel.reel_scenes).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(ReelScene.new))
      end

      it 'continues processing other scenes' do
        result = service.call

        expect(result.success?).to be true
        expect(result.data[:created_scenes]).to eq(0)
      end
    end

    context 'when unexpected error occurs during scene creation' do
      before do
        allow(reel.reel_scenes).to receive(:create!).and_raise(StandardError.new("Database connection lost"))
      end

      it 'handles the error gracefully and continues' do
        expect(Rails.logger).to receive(:error).with(/Unexpected error creating scene/).at_least(:once)
        expect(Rails.logger).to receive(:error).with(/Scene data:/).at_least(:once)
        expect(Rails.logger).to receive(:error).with(/Backtrace:/).at_least(:once)

        result = service.call

        expect(result.success?).to be true
        expect(result.data[:created_scenes]).to eq(0)
      end
    end

    context 'when service fails completely' do
      before do
        allow(service).to receive(:resolve_default_avatar_and_voice).and_raise(StandardError.new("Critical failure"))
      end

      it 'returns failure result with error message' do
        expect(Rails.logger).to receive(:error).with(/Failed to preload scenes: Critical failure/)
        expect(Rails.logger).to receive(:error).with(/Backtrace:/)

        result = service.call

        expect(result.success?).to be false
        expect(result.error).to include("Scene preload failed: Critical failure")
      end
    end

    context 'with scenes having custom avatar and voice IDs' do
      let(:custom_scenes) do
        [
          {
            "voiceover" => "Custom scene",
            "avatar_id" => "custom_avatar_123",
            "voice_id" => "custom_voice_456"
          }
        ]
      end

      let(:service_with_custom) do
        described_class.new(
          reel: reel,
          scenes: custom_scenes,
          current_user: user
        )
      end

      before do
        # Ensure clean state - no existing avatars/voices
        user.avatars.destroy_all
        user.voices.destroy_all
        # Prevent reel from requiring additional scenes
        allow(reel).to receive(:requires_scenes?).and_return(false)
      end

      it 'processes scenes with custom IDs successfully' do
        # This test verifies that scenes with custom avatar/voice IDs are processed
        result = service_with_custom.call
        reel.reload

        scene = reel.reel_scenes.first
        expect(scene).to be_present
        expect(scene.script).to eq("Custom scene")
        expect(scene.avatar_id).to be_present
        expect(scene.voice_id).to be_present
        expect(result.success?).to be true
      end
    end
  end
end
