require 'rails_helper'

RSpec.describe Reels::FormSetupService do
  let(:user) { create(:user) }
  let(:template) { "only_avatars" }

  describe '#call' do
    context 'with valid template' do
      it 'returns success with reel and presenter data' do
        result = described_class.new(user: user, template: template).call

        expect(result[:success]).to be true
        expect(result[:data][:reel]).to be_present
        expect(result[:data][:reel].template).to eq(template)
        expect(result[:data][:reel].new_record?).to be true
        expect(result[:data][:presenter]).to be_present
        expect(result[:data][:view_template]).to be_present
      end

      it 'builds scenes for scene-based templates' do
        result = described_class.new(user: user, template: "only_avatars").call

        reel = result[:data][:reel]
        expect(reel.reel_scenes.size).to eq(3)
        expect(reel.reel_scenes.map(&:scene_number)).to eq([ 1, 2, 3 ])
      end

      it 'does not build scenes for non-scene-based templates' do
        result = described_class.new(user: user, template: "narration_over_7_images").call

        reel = result[:data][:reel]
        expect(reel.reel_scenes.size).to eq(0)
      end
    end

    context 'with smart planning data' do
      let(:smart_planning_data) do
        {
          title: "Smart Planning Test",
          description: "Test description",
          shotplan: {
            scenes: [
              { voiceover: "Scene 1 script", avatar_id: "avatar_123" },
              { voiceover: "Scene 2 script" }
            ]
          }
        }.to_json
      end

      it 'applies smart planning data to reel' do
        result = described_class.new(
          user: user,
          template: template,
          smart_planning_data: smart_planning_data
        ).call

        reel = result[:data][:reel]
        expect(reel.title).to eq("Smart Planning Test")
        expect(reel.description).to eq("Test description")
        expect(reel.reel_scenes.size).to eq(2)
        expect(reel.reel_scenes.first.script).to eq("Scene 1 script")
      end
    end

    context 'with invalid template' do
      it 'returns failure for invalid template' do
        result = described_class.new(user: user, template: "invalid_template").call

        expect(result[:success]).to be false
        expect(result[:error]).to be_present
      end
    end
  end
end
