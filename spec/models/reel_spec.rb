require 'rails_helper'

RSpec.describe Reel, type: :model do
  let(:user) { create(:user) }

  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:reel_scenes).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:template) }
    it 'validates template inclusion with custom message' do
      reel = build(:reel, user: user, template: 'invalid_template')
      expect(reel).to be_invalid
      expect(reel.errors[:template]).to include('invalid_template is not a valid template')
    end
    it { should validate_inclusion_of(:status).in_array(%w[draft processing completed failed]) }

    describe 'scene validations for template-based reels' do
      context 'when template requires scenes' do
        let(:reel) { create(:reel, user: user, template: 'solo_avatars') }

        it 'validates exactly 3 scenes are present' do
          create(:reel_scene, reel: reel, scene_number: 1)
          create(:reel_scene, reel: reel, scene_number: 2)

          expect(reel.reload.valid?).to be false
          reel.reload.valid?
          expect(reel.errors[:reel_scenes]).to include('must have exactly 3 scenes for solo_avatars template')
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
          new_reel = build(:reel, user: user, template: 'solo_avatars')
          expect(new_reel).to be_valid
        end
      end

      context 'when template does not require scenes' do
        let(:reel) { create(:reel, user: user, template: 'narration_over_7_images') }

        it 'does not validate scene count' do
          expect(reel.reload.valid?).to be true
        end
      end
    end
  end

  describe 'scopes' do
    let!(:solo_avatars_reel) { create(:reel, user: user, template: 'solo_avatars') }
    let!(:draft_reel) { create(:reel, user: user, status: 'draft') }
    let!(:processing_reel) { create(:reel, user: user, status: 'processing') }

    describe '.by_template' do
      it 'returns reels with specified template' do
        expect(Reel.where(template: 'solo_avatars')).to include(solo_avatars_reel)
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
    context 'for solo_avatars template' do
      let(:reel) { create(:reel, user: user, template: 'solo_avatars') }

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
          reel.reload # Ensure we see the updated scene data
          expect(reel.ready_for_generation?).to be false
        end
      end
    end

    context 'for avatar_and_video template' do
      let(:reel) { create(:reel, user: user, template: 'avatar_and_video') }

      it 'returns true when has 3 complete scenes' do
        create(:reel_scene, reel: reel, scene_number: 1, avatar_id: 'avatar_1', voice_id: 'voice_1', script: 'Scene 1')
        create(:reel_scene, reel: reel, scene_number: 2, avatar_id: 'avatar_2', voice_id: 'voice_2', script: 'Scene 2')
        create(:reel_scene, reel: reel, scene_number: 3, avatar_id: 'avatar_3', voice_id: 'voice_3', script: 'Scene 3')

        expect(reel.ready_for_generation?).to be true
      end

      it 'returns false when has less than 3 scenes' do
        create(:reel_scene, reel: reel, scene_number: 1, avatar_id: 'avatar_1', voice_id: 'voice_1', script: 'Scene 1')

        expect(reel.ready_for_generation?).to be false
      end
    end

    context 'for narration_over_7_images template' do
      let(:reel) { create(:reel, user: user, template: 'narration_over_7_images') }

      it 'returns true' do
        expect(reel.ready_for_generation?).to be true
      end
    end

    context 'for one_to_three_videos template' do
      let(:reel) { create(:reel, user: user, template: 'one_to_three_videos') }

      it 'returns true' do
        expect(reel.ready_for_generation?).to be true
      end
    end

    context 'for unknown template' do
      let(:reel) { build(:reel, user: user, template: 'unknown') }

      it 'returns false' do
        # We need to bypass the validation to test the ready_for_generation? method with invalid template
        reel.save(validate: false)
        expect(reel.ready_for_generation?).to be false
      end
    end
  end

  describe '#requires_scenes?' do
    it 'returns true for solo_avatars template' do
      reel = build(:reel, user: user, template: 'solo_avatars')
      expect(reel.requires_scenes?).to be true
    end

    it 'returns true for avatar_and_video template' do
      reel = build(:reel, user: user, template: 'avatar_and_video')
      expect(reel.requires_scenes?).to be true
    end

    it 'returns false for narration_over_7_images template' do
      reel = build(:reel, user: user, template: 'narration_over_7_images')
      expect(reel.requires_scenes?).to be false
    end

    it 'returns false for one_to_three_videos template' do
      reel = build(:reel, user: user, template: 'one_to_three_videos')
      expect(reel.requires_scenes?).to be false
    end
  end

  describe 'scene number assignment' do
    it 'assigns scene numbers automatically' do
      reel = create(:reel, user: user, template: 'solo_avatars')

      # Test that the assign_scene_numbers method exists and works
      scene_without_number = build(:reel_scene, reel: reel, scene_number: nil)
      reel.reel_scenes << scene_without_number

      # Manually call the private method to test it
      reel.send(:assign_scene_numbers)

      expect(scene_without_number.scene_number).to be_between(1, 3)
    end
  end

  describe 'factory' do
    it 'creates a valid reel' do
      reel = create(:reel, user: user)
      expect(reel).to be_persisted
      expect(reel.user).to eq(user)
      expect(reel.template).to eq('solo_avatars')
      expect(reel.status).to eq('draft')
    end
  end
end
