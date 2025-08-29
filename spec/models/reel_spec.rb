require 'rails_helper'

RSpec.describe Reel, type: :model do
  let(:user) { create(:user) }

  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:reel_scenes).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:mode) }
    it { should validate_inclusion_of(:mode).in_array(%w[scene_based narrative]) }
    it { should validate_inclusion_of(:status).in_array(%w[draft processing completed failed]) }

    describe 'scene validations for scene_based mode' do
      context 'when mode is scene_based' do
        let(:reel) { create(:reel, user: user, mode: 'scene_based') }

        it 'validates exactly 3 scenes are present' do
          create(:reel_scene, reel: reel, scene_number: 1)
          create(:reel_scene, reel: reel, scene_number: 2)

          expect(reel.reload.valid?).to be false
          reel.reload.valid?
          expect(reel.errors[:reel_scenes]).to include('must have exactly 3 scenes for scene_based mode')
        end

        it 'is valid with exactly 3 scenes' do
          create(:reel_scene, reel: reel, scene_number: 1)
          create(:reel_scene, reel: reel, scene_number: 2)
          create(:reel_scene, reel: reel, scene_number: 3)

          expect(reel.reload.valid?).to be true
        end

        it 'validates all scenes are complete' do
          create(:reel_scene, reel: reel, scene_number: 1, script: 'Complete scene')
          create(:reel_scene, reel: reel, scene_number: 2, script: 'Valid script')
          create(:reel_scene, reel: reel, scene_number: 3, script: 'Valid script')

          # Update scenes to be incomplete using update_column to bypass validations
          reel.reel_scenes.by_scene_number(2).first.update_column(:script, '')
          reel.reel_scenes.by_scene_number(3).first.update_column(:script, nil)

          expect(reel.reload.valid?).to be false
          reel.reload.valid?
          expect(reel.errors[:reel_scenes]).to include('scenes 2, 3 are incomplete')
        end

        it 'skips validation for new records' do
          new_reel = build(:reel, user: user, mode: 'scene_based')
          expect(new_reel).to be_valid
        end
      end

      context 'when mode is narrative' do
        let(:reel) { create(:reel, user: user, mode: 'narrative') }

        it 'does not validate scene count' do
          expect(reel.reload.valid?).to be true
        end
      end
    end
  end

  describe 'scopes' do
    let!(:scene_reel) { create(:reel, user: user, mode: 'scene_based') }
    let!(:draft_reel) { create(:reel, user: user, status: 'draft') }
    let!(:processing_reel) { create(:reel, user: user, status: 'processing') }

    describe '.scene_based' do
      it 'returns only scene_based reels' do
        expect(Reel.scene_based).to include(scene_reel)
      end
    end

    describe '.by_status' do
      it 'returns reels with specified status' do
        expect(Reel.by_status('draft')).to include(draft_reel)
        expect(Reel.by_status('processing')).to include(processing_reel)
        expect(Reel.by_status('draft')).not_to include(processing_reel)
      end
    end
  end

  describe '#ready_for_generation?' do
    let(:reel) { create(:reel, user: user, mode: 'scene_based') }

    context 'when reel has exactly 3 complete scenes' do
      before do
        create(:reel_scene, reel: reel, scene_number: 1, avatar_id: 'avatar_1', voice_id: 'voice_1', script: 'Scene 1')
        create(:reel_scene, reel: reel, scene_number: 2, avatar_id: 'avatar_2', voice_id: 'voice_2', script: 'Scene 2')
        create(:reel_scene, reel: reel, scene_number: 3, avatar_id: 'avatar_3', voice_id: 'voice_3', script: 'Scene 3')
      end

      it 'returns true' do
        expect(reel.ready_for_generation?).to be true
      end
    end

    context 'when reel has less than 3 scenes' do
      before do
        create(:reel_scene, reel: reel, scene_number: 1)
        create(:reel_scene, reel: reel, scene_number: 2)
      end

      it 'returns false' do
        expect(reel.ready_for_generation?).to be false
      end
    end

    context 'when reel has incomplete scenes' do
      before do
        create(:reel_scene, reel: reel, scene_number: 1, avatar_id: 'avatar_1', voice_id: 'voice_1', script: 'Scene 1')
        scene_2 = create(:reel_scene, reel: reel, scene_number: 2, avatar_id: 'avatar_2', voice_id: 'voice_2', script: 'Valid script')
        scene_2.update_column(:script, '') # Bypass validation to test incomplete scene
        create(:reel_scene, reel: reel, scene_number: 3, avatar_id: 'avatar_3', voice_id: 'voice_3', script: 'Scene 3')
      end

      it 'returns false' do
        expect(reel.ready_for_generation?).to be false
      end
    end

    context 'when mode is not scene_based' do
      let(:reel) { create(:reel, user: user, mode: 'narrative') }

      it 'returns false' do
        expect(reel.ready_for_generation?).to be false
      end
    end
  end

  describe 'factory' do
    it 'creates a valid reel' do
      reel = create(:reel, user: user)
      expect(reel).to be_persisted
      expect(reel.user).to eq(user)
      expect(reel.mode).to eq('scene_based')
      expect(reel.status).to eq('draft')
    end
  end
end
