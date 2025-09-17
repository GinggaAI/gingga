require 'rails_helper'

RSpec.describe ReelScene, type: :model do
  let(:user) { create(:user) }
  let(:reel) { create(:reel, user: user) }

  describe 'associations' do
    it { should belong_to(:reel) }
  end

  describe 'validations' do
    it { should validate_presence_of(:scene_number) }
    it { should validate_inclusion_of(:scene_number).in_range(1..3) }

    context 'conditional validations based on reel status' do
      context 'when reel is in draft status' do
        let(:draft_reel) { create(:reel, user: user, status: 'draft') }

        it 'does not require avatar_id for draft reels' do
          scene = build(:reel_scene, reel: draft_reel, avatar_id: nil, voice_id: 'voice_1', script: 'test', video_type: 'avatar')
          expect(scene).to be_valid
        end

        it 'does not require voice_id for draft reels' do
          scene = build(:reel_scene, reel: draft_reel, avatar_id: 'avatar_1', voice_id: nil, script: 'test', video_type: 'avatar')
          expect(scene).to be_valid
        end

        it 'does not require script for draft reels' do
          scene = build(:reel_scene, reel: draft_reel, avatar_id: 'avatar_1', voice_id: 'voice_1', script: nil, video_type: 'avatar')
          expect(scene).to be_valid
        end

        it 'does not require video_type for draft reels' do
          scene = build(:reel_scene, reel: draft_reel, avatar_id: 'avatar_1', voice_id: 'voice_1', script: 'test', video_type: nil)
          expect(scene).to be_valid
        end
      end

      context 'when reel is not in draft status' do
        let(:non_draft_reel) { create(:reel, user: user, status: 'processing') }

        it 'validates normally when reel is not draft' do
          scene = build(:reel_scene, reel: non_draft_reel)
          expect(scene).to be_valid # Should be valid with default factory attributes
        end
      end
    end

    describe 'scene_number uniqueness' do
      let!(:existing_scene) { create(:reel_scene, reel: reel, scene_number: 1) }

      it 'validates uniqueness of scene_number within reel scope' do
        duplicate_scene = build(:reel_scene, reel: reel, scene_number: 1)

        expect(duplicate_scene).not_to be_valid
        expect(duplicate_scene.errors[:scene_number]).to include('has already been taken')
      end

      it 'allows same scene_number in different reels' do
        other_reel = create(:reel, user: user)
        other_scene = build(:reel_scene, reel: other_reel, scene_number: 1)

        expect(other_scene).to be_valid
      end
    end
  end

  describe 'scopes' do
    let!(:scene_1) { create(:reel_scene, reel: reel, scene_number: 1) }
    let!(:scene_3) { create(:reel_scene, reel: reel, scene_number: 3) }
    let!(:scene_2) { create(:reel_scene, reel: reel, scene_number: 2) }

    describe '.ordered' do
      it 'returns scenes ordered by scene_number' do
        ordered_scenes = reel.reel_scenes.ordered
        expect(ordered_scenes.pluck(:scene_number)).to eq([ 1, 2, 3 ])
      end
    end

    describe '.by_scene_number' do
      it 'returns scenes with specified scene_number' do
        scenes = reel.reel_scenes.by_scene_number(2)
        expect(scenes).to include(scene_2)
        expect(scenes).not_to include(scene_1)
      end
    end
  end

  describe '#complete?' do
    context 'with avatar video type' do
      context 'when all required fields are present' do
        let(:scene) { build(:reel_scene, reel: reel, avatar_id: 'avatar_1', voice_id: 'voice_1', script: 'Test script', video_type: 'avatar') }

        it 'returns true' do
          expect(scene.complete?).to be true
        end
      end

      context 'when avatar_id is missing' do
        let(:scene) { build(:reel_scene, reel: reel, avatar_id: nil, voice_id: 'voice_1', script: 'Test script', video_type: 'avatar') }

        it 'returns false' do
          expect(scene.complete?).to be false
        end
      end
    end

    context 'with kling video type' do
      context 'when required fields are present (no avatar_id needed)' do
        let(:scene) { build(:reel_scene, reel: reel, avatar_id: nil, voice_id: 'voice_1', script: 'Test script', video_type: 'kling') }

        it 'returns true even without avatar_id' do
          expect(scene.complete?).to be true
        end
      end

      context 'when voice_id is missing' do
        let(:scene) { build(:reel_scene, reel: reel, avatar_id: nil, voice_id: nil, script: 'Test script', video_type: 'kling') }

        it 'returns false' do
          expect(scene.complete?).to be false
        end
      end
    end

    context 'with unknown video type' do
      context 'when all fields are present including avatar_id' do
        let(:scene) { build(:reel_scene, reel: reel, avatar_id: 'avatar_1', voice_id: 'voice_1', script: 'Test script', video_type: 'unknown_type') }

        it 'returns true (requires avatar_id for unknown types)' do
          expect(scene.complete?).to be true
        end
      end

      context 'when avatar_id is missing' do
        let(:scene) { build(:reel_scene, reel: reel, avatar_id: nil, voice_id: 'voice_1', script: 'Test script', video_type: 'unknown_type') }

        it 'returns false (requires avatar_id for unknown types)' do
          expect(scene.complete?).to be false
        end
      end
    end

    context 'when voice_id is missing' do
      let(:scene) { build(:reel_scene, reel: reel, avatar_id: 'avatar_1', voice_id: nil, script: 'Test script', video_type: 'avatar') }

      it 'returns false' do
        expect(scene.complete?).to be false
      end
    end

    context 'when script is missing' do
      let(:scene) { build(:reel_scene, reel: reel, avatar_id: 'avatar_1', voice_id: 'voice_1', script: nil, video_type: 'avatar') }

      it 'returns false' do
        expect(scene.complete?).to be false
      end
    end

    context 'when script is empty' do
      let(:scene) { build(:reel_scene, reel: reel, avatar_id: 'avatar_1', voice_id: 'voice_1', script: '', video_type: 'avatar') }

      it 'returns false' do
        expect(scene.complete?).to be false
      end
    end

    context 'when video_type is missing' do
      let(:scene) { build(:reel_scene, reel: reel, avatar_id: 'avatar_1', voice_id: 'voice_1', script: 'Test script', video_type: nil) }

      it 'returns false' do
        expect(scene.complete?).to be false
      end
    end
  end

  describe '#to_heygen_payload' do
    let(:scene) { build(:reel_scene, reel: reel, avatar_id: 'avatar_123', voice_id: 'voice_456', script: 'Hello world', video_type: 'avatar') }

    it 'returns hash with heygen API format' do
      payload = scene.to_heygen_payload

      expect(payload).to eq({
        avatar_id: 'avatar_123',
        voice_id: 'voice_456',
        script: 'Hello world',
        video_type: 'avatar'
      })
    end
  end

  describe 'factory' do
    it 'creates a valid reel scene' do
      scene = create(:reel_scene, reel: reel)

      expect(scene).to be_persisted
      expect(scene.reel).to eq(reel)
      expect(scene.scene_number).to be_between(1, 3)
      expect(scene.avatar_id).to be_present
      expect(scene.voice_id).to be_present
      expect(scene.script).to be_present
    end

    it 'creates scenes with different scene_numbers when creating multiple' do
      scene_1 = create(:reel_scene, reel: reel, scene_number: 1)
      scene_2 = create(:reel_scene, reel: reel, scene_number: 2)
      scene_3 = create(:reel_scene, reel: reel, scene_number: 3)

      expect([ scene_1.scene_number, scene_2.scene_number, scene_3.scene_number ]).to match_array([ 1, 2, 3 ])
    end
  end

  describe 'private methods' do
    describe '#reel_is_draft?' do
      context 'when reel is in draft status' do
        let(:draft_reel) { create(:reel, user: user, status: 'draft') }
        let(:scene) { build(:reel_scene, reel: draft_reel) }

        it 'returns true' do
          expect(scene.send(:reel_is_draft?)).to be true
        end
      end

      context 'when reel is not in draft status' do
        let(:processing_reel) { create(:reel, user: user, status: 'processing') }
        let(:scene) { build(:reel_scene, reel: processing_reel) }

        it 'returns false' do
          expect(scene.send(:reel_is_draft?)).to be false
        end
      end

      context 'when reel is nil' do
        let(:scene) { build(:reel_scene, reel: nil) }

        it 'returns false' do
          expect(scene.send(:reel_is_draft?)).to be false
        end
      end
    end
  end
end
