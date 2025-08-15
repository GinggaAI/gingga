require 'rails_helper'

RSpec.describe BrandChannel, type: :model do
  describe 'associations' do
    it { should belong_to(:brand) }
  end

  describe 'validations' do
    it { should validate_presence_of(:platform) }
  end

  describe 'enums' do
    it { should define_enum_for(:platform).with_values(instagram: 0, tiktok: 1, youtube: 2, linkedin: 3) }
  end

  describe 'enum values' do
    let(:brand_channel) { create(:brand_channel) }

    it 'can be set to instagram' do
      brand_channel.instagram!
      expect(brand_channel.platform).to eq('instagram')
    end

    it 'can be set to tiktok' do
      brand_channel.tiktok!
      expect(brand_channel.platform).to eq('tiktok')
    end

    it 'can be set to youtube' do
      brand_channel.youtube!
      expect(brand_channel.platform).to eq('youtube')
    end

    it 'can be set to linkedin' do
      brand_channel.linkedin!
      expect(brand_channel.platform).to eq('linkedin')
    end
  end
end
