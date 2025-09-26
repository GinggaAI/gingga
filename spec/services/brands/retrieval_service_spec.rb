require 'rails_helper'

RSpec.describe Brands::RetrievalService do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }

  describe '#call' do
    context 'without brand_id parameter' do
      it 'returns the first brand for user' do
        brand # create brand
        service = described_class.new(user: user)

        result = service.call

        expect(result[:success]).to be true
        expect(result[:data][:brand]).to eq(brand)
      end

      it 'returns nil when user has no brands' do
        service = described_class.new(user: user)

        result = service.call

        expect(result[:success]).to be true
        expect(result[:data][:brand]).to be_nil
      end
    end

    context 'with brand_id parameter' do
      it 'returns the specific brand when found' do
        brand # create brand
        service = described_class.new(user: user, brand_id: brand.id)

        result = service.call

        expect(result[:success]).to be true
        expect(result[:data][:brand]).to eq(brand)
      end

      it 'raises error when brand not found' do
        service = described_class.new(user: user, brand_id: 'non-existent-id')

        result = service.call

        expect(result[:success]).to be false
        expect(result[:error]).to include('An error occurred')
      end
    end

    context 'with eager loading enabled' do
      it 'preloads associations when eager_load is true' do
        brand_with_audiences = create(:brand, user: user)
        create(:audience, brand: brand_with_audiences)

        service = described_class.new(user: user, brand_id: brand_with_audiences.id, eager_load: true)
        result = service.call

        expect(result[:success]).to be true
        loaded_brand = result[:data][:brand]
        expect(loaded_brand.association(:audiences)).to be_loaded
      end
    end

    context 'without user' do
      it 'returns error when user is nil' do
        service = described_class.new(user: nil)

        result = service.call

        expect(result[:success]).to be false
        expect(result[:error]).to eq('User is required')
      end
    end
  end

  describe '.for_edit' do
    context 'when user has brands' do
      it 'returns brand with preloaded associations' do
        brand_with_data = create(:brand, user: user)
        create(:audience, brand: brand_with_data)

        result_brand = described_class.for_edit(user: user, brand_id: brand_with_data.id)

        expect(result_brand).to eq(brand_with_data)
        expect(result_brand.association(:audiences)).to be_loaded
      end
    end

    context 'when user has no brands' do
      it 'returns new brand with initialized associations' do
        result_brand = described_class.for_edit(user: user)

        expect(result_brand).to be_new_record
        expect(result_brand.user).to eq(user)
        expect(result_brand.association(:audiences)).to be_loaded
        expect(result_brand.audiences.length).to eq(0)
      end
    end
  end

  describe '.collection_for_user' do
    it 'returns brands with preloaded associations ordered by created_at' do
      older_brand = create(:brand, user: user, created_at: 1.day.ago)
      newer_brand = create(:brand, user: user, created_at: 1.hour.ago)

      brands = described_class.collection_for_user(user: user)

      expect(brands).to eq([older_brand, newer_brand])
      expect(brands.first.association(:audiences)).to be_loaded
    end
  end
end