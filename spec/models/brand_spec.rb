require 'rails_helper'

RSpec.describe Brand, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:audiences).dependent(:destroy) }
    it { should have_many(:products).dependent(:destroy) }
    it { should have_many(:brand_channels).dependent(:destroy) }
    it { should have_many(:creas_strategy_plans).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:slug) }
    it { should validate_presence_of(:industry) }
    it { should validate_presence_of(:voice) }

    describe 'slug uniqueness' do
      let(:user) { create(:user) }
      let!(:existing_brand) { create(:brand, user: user, slug: 'test-brand') }

      it 'validates uniqueness of slug within user scope' do
        new_brand = build(:brand, user: user, slug: 'test-brand')
        expect(new_brand).not_to be_valid
        expect(new_brand.errors[:slug]).to include("has already been taken")
      end

      it 'allows same slug for different users' do
        other_user = create(:user)
        new_brand = build(:brand, user: other_user, slug: 'test-brand')
        expect(new_brand).to be_valid
      end
    end
  end

  describe 'JSONB defaults' do
    let(:brand) { Brand.new(user: create(:user), name: 'Test', slug: 'test', industry: 'Tech', voice: 'friendly') }

    it 'has default empty arrays for subtitle_languages' do
      expect(brand.subtitle_languages).to eq([])
    end

    it 'has default empty arrays for dub_languages' do
      expect(brand.dub_languages).to eq([])
    end

    it 'has default guardrails structure' do
      expect(brand.guardrails).to include('banned_words', 'claims_rules', 'tone_no_go')
    end

    it 'has default resources structure' do
      expect(brand.resources).to include('podcast_clips', 'editing', 'ai_avatars', 'kling', 'stock', 'budget')
    end
  end
end
