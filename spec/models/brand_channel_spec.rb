require 'rails_helper'

RSpec.describe BrandChannel, type: :model do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }

  describe 'associations' do
    it { should belong_to(:brand) }
  end

  describe 'validations' do
    it { should validate_presence_of(:platform) }
    it { should validate_presence_of(:handle) }

    describe 'platform uniqueness' do
      let!(:existing_channel) { create(:brand_channel, brand: brand, platform: :instagram) }

      it 'validates uniqueness of platform within brand scope' do
        duplicate_channel = build(:brand_channel, brand: brand, platform: :instagram)
        expect(duplicate_channel).not_to be_valid
        expect(duplicate_channel.errors[:platform]).to include('has already been taken')
      end

      it 'allows same platform for different brands' do
        other_brand = create(:brand, user: user)
        same_platform_channel = build(:brand_channel, brand: other_brand, platform: :instagram)
        expect(same_platform_channel).to be_valid
      end
    end
  end

  describe 'enums' do
    it { should define_enum_for(:platform).with_values(instagram: 0, tiktok: 1, youtube: 2, linkedin: 3) }
  end

  describe 'enum values' do
    let(:brand_channel) { create(:brand_channel, brand: brand) }

    it 'can be set to instagram' do
      brand_channel.instagram!
      expect(brand_channel.platform).to eq('instagram')
      expect(brand_channel.instagram?).to be true
    end

    it 'can be set to tiktok' do
      brand_channel.tiktok!
      expect(brand_channel.platform).to eq('tiktok')
      expect(brand_channel.tiktok?).to be true
    end

    it 'can be set to youtube' do
      brand_channel.youtube!
      expect(brand_channel.platform).to eq('youtube')
      expect(brand_channel.youtube?).to be true
    end

    it 'can be set to linkedin' do
      brand_channel.linkedin!
      expect(brand_channel.platform).to eq('linkedin')
      expect(brand_channel.linkedin?).to be true
    end
  end

  describe 'creation' do
    it 'can be created with valid attributes' do
      channel = BrandChannel.new(
        brand: brand,
        platform: :instagram,
        handle: '@testbrand',
        priority: 1
      )

      expect(channel).to be_valid
      expect { channel.save! }.not_to raise_error
    end

    it 'cannot be created without a platform' do
      channel = build(:brand_channel, brand: brand, platform: nil)
      expect(channel).not_to be_valid
      expect(channel.errors[:platform]).to include("can't be blank")
    end

    it 'cannot be created without a handle' do
      channel = build(:brand_channel, brand: brand, handle: nil)
      expect(channel).not_to be_valid
      expect(channel.errors[:handle]).to include("can't be blank")
    end

    it 'cannot be created without a brand' do
      channel = build(:brand_channel, brand: nil)
      expect(channel).not_to be_valid
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      channel = build(:brand_channel, brand: brand)
      expect(channel).to be_valid
    end

    it 'has a valid tiktok factory' do
      channel = build(:brand_channel, :tiktok, brand: brand)
      expect(channel).to be_valid
      expect(channel.tiktok?).to be true
    end
  end
end
