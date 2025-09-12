require 'rails_helper'

RSpec.describe Reels::SmartPlanningControllerService do
  let(:user) { create(:user) }
  let(:reel) { user.reels.build(template: "only_avatars") }

  describe '#call' do
    context 'with no smart planning data' do
      it 'returns success without changes' do
        result = described_class.new(
          reel: reel,
          smart_planning_data: nil,
          current_user: user
        ).call

        expect(result[:success]).to be true
        expect(reel.title).to be_nil
      end
    end

    context 'with valid smart planning data' do
      let(:smart_planning_data) do
        {
          title: "Preloaded Title",
          description: "Preloaded Description",
          shotplan: {
            scenes: [
              { voiceover: "Scene 1 script", avatar_id: "custom_avatar" },
              { script: "Scene 2 script" }
            ]
          }
        }.to_json
      end

      before do
        # Build initial scenes
        3.times { |i| reel.reel_scenes.build(scene_number: i + 1) }
      end

      it 'applies basic reel information' do
        result = described_class.new(
          reel: reel,
          smart_planning_data: smart_planning_data,
          current_user: user
        ).call

        expect(result[:success]).to be true
        expect(reel.title).to eq("Preloaded Title")
        expect(reel.description).to eq("Preloaded Description")
      end

      it 'preloads scene data' do
        result = described_class.new(
          reel: reel,
          smart_planning_data: smart_planning_data,
          current_user: user
        ).call

        expect(result[:success]).to be true
        expect(reel.reel_scenes.size).to eq(2) # Should replace existing scenes

        first_scene = reel.reel_scenes.first
        expect(first_scene.script).to eq("Scene 1 script")
        expect(first_scene.avatar_id).to eq("custom_avatar")

        second_scene = reel.reel_scenes.second
        expect(second_scene.script).to eq("Scene 2 script")
        expect(second_scene.avatar_id).to eq("avatar_001") # Default fallback
      end
    end

    context 'with invalid JSON' do
      it 'handles invalid JSON gracefully' do
        result = described_class.new(
          reel: reel,
          smart_planning_data: "invalid json {",
          current_user: user
        ).call

        expect(result[:success]).to be false
        expect(result[:error]).to include("Invalid planning data format")
      end
    end

    context 'with scenes missing script content' do
      let(:smart_planning_data) do
        {
          title: "Test Title",
          shotplan: {
            scenes: [
              { voiceover: "Valid scene" },
              { avatar_id: "avatar_123" }, # Missing script
              { script: "Another valid scene" }
            ]
          }
        }.to_json
      end

      it 'skips scenes without script content' do
        result = described_class.new(
          reel: reel,
          smart_planning_data: smart_planning_data,
          current_user: user
        ).call

        expect(result[:success]).to be true
        expect(reel.reel_scenes.size).to eq(2) # Should skip the middle scene
        expect(reel.reel_scenes.map(&:script)).to eq([ "Valid scene", "Another valid scene" ])
        expect(reel.reel_scenes.map(&:scene_number)).to eq([ 1, 3 ]) # Preserves original scene numbers
      end
    end
  end
end
