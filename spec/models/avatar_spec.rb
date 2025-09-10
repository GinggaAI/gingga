require 'rails_helper'

RSpec.describe Avatar, type: :model do
  describe 'associations' do
    it 'belongs to user' do
      expect(Avatar.reflect_on_association(:user).macro).to eq(:belongs_to)
    end
  end

  describe 'validations' do
    subject { build(:avatar) }

    it 'validates presence of avatar_id' do
      subject.avatar_id = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:avatar_id]).to include("can't be blank")
    end

    it 'validates presence of name' do
      subject.name = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:name]).to include("can't be blank")
    end

    it 'validates presence of provider' do
      subject.provider = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:provider]).to include("can't be blank")
    end

    it 'validates provider is in allowed list' do
      subject.provider = 'invalid_provider'
      expect(subject).not_to be_valid
      expect(subject.errors[:provider]).to include('is not included in the list')
    end

    it 'validates uniqueness of avatar_id scoped to user and provider' do
      user = create(:user)
      existing_avatar = create(:avatar, user: user, avatar_id: 'test_avatar_123', provider: 'heygen')
      duplicate_avatar = build(:avatar, user: user, avatar_id: 'test_avatar_123', provider: 'heygen')

      expect(duplicate_avatar).not_to be_valid
      expect(duplicate_avatar.errors[:avatar_id]).to include('has already been taken')
    end

    it 'allows same avatar_id for different users' do
      other_user = create(:user)
      create(:avatar, user: other_user, avatar_id: 'test_avatar_123', provider: 'heygen')

      subject.avatar_id = 'test_avatar_123'
      subject.provider = 'heygen'

      expect(subject).to be_valid
    end

    it 'allows same avatar_id for different providers' do
      create(:avatar, user: subject.user, avatar_id: 'test_avatar_123', provider: 'heygen')

      subject.avatar_id = 'test_avatar_123'
      subject.provider = 'kling'

      expect(subject).to be_valid
    end
  end

  describe 'scopes' do
    let!(:user) { create(:user) }
    let!(:heygen_avatar) { create(:avatar, user: user, provider: 'heygen') }
    let!(:kling_avatar) { create(:avatar, user: user, provider: 'kling') }

    it 'filters by provider' do
      expect(Avatar.by_provider('heygen')).to include(heygen_avatar)
      expect(Avatar.by_provider('heygen')).not_to include(kling_avatar)
    end

    it 'filters by active status' do
      active_avatar = create(:avatar, user: user, status: 'active')
      inactive_avatar = create(:avatar, user: user, status: 'inactive')

      expect(Avatar.active).to include(active_avatar)
      expect(Avatar.active).not_to include(inactive_avatar)
    end
  end

  describe 'instance methods' do
    let(:avatar) { build(:avatar, status: 'active') }

    describe '#active?' do
      it 'returns true when status is active' do
        avatar.status = 'active'
        expect(avatar.active?).to be true
      end

      it 'returns false when status is not active' do
        avatar.status = 'inactive'
        expect(avatar.active?).to be false
      end
    end

    describe '#to_api_format' do
      let(:avatar) do
        build(:avatar,
          avatar_id: 'avatar_123',
          name: 'Professional Male',
          preview_image_url: 'https://example.com/preview.jpg',
          gender: 'male',
          is_public: true,
          provider: 'heygen'
        )
      end

      it 'returns avatar data in API format' do
        expected_format = {
          id: 'avatar_123',
          name: 'Professional Male',
          preview_image_url: 'https://example.com/preview.jpg',
          gender: 'male',
          is_public: true,
          provider: 'heygen'
        }

        expect(avatar.to_api_format).to eq(expected_format)
      end
    end
  end
end
