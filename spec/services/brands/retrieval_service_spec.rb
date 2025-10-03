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
      it 'returns brand successfully (eager_load parameter now ignored)' do
        brand_with_data = create(:brand, user: user)
        create(:audience, brand: brand_with_data)
        create(:product, brand: brand_with_data)
        create(:brand_channel, brand: brand_with_data)

        service = described_class.new(user: user, brand_id: brand_with_data.id, eager_load: true)
        result = service.call

        expect(result[:success]).to be true
        loaded_brand = result[:data][:brand]

        # Verify associations can be accessed (now lazy loaded)
        expect(loaded_brand.audiences.order(:created_at).count).to eq(1)
        expect(loaded_brand.products.order(:created_at).count).to eq(1)
        expect(loaded_brand.brand_channels.order(:priority, :created_at).count).to eq(1)

        # Counter cache should work
        expect(loaded_brand.audiences_count).to eq(1)
        expect(loaded_brand.products_count).to eq(1)
        expect(loaded_brand.brand_channels_count).to eq(1)
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
      it 'returns brand ready for edit form' do
        brand_with_data = create(:brand, user: user)
        create(:audience, brand: brand_with_data)
        create(:product, brand: brand_with_data)
        create(:brand_channel, brand: brand_with_data)

        result_brand = described_class.for_edit(user: user, brand_id: brand_with_data.id)

        expect(result_brand).to eq(brand_with_data)

        # Verify associations can be accessed and counter cache works
        expect(result_brand.audiences.order(:created_at).count).to eq(1)
        expect(result_brand.products.order(:created_at).count).to eq(1)
        expect(result_brand.brand_channels.order(:priority, :created_at).count).to eq(1)

        # Counter cache should work
        expect(result_brand.audiences_count).to eq(1)
        expect(result_brand.products_count).to eq(1)
        expect(result_brand.brand_channels_count).to eq(1)
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
    it 'returns brands ordered by created_at without preloading associations' do
      older_brand = create(:brand, user: user, created_at: 1.day.ago)
      newer_brand = create(:brand, user: user, created_at: 1.hour.ago)

      brands = described_class.collection_for_user(user: user)

      expect(brands).to eq([ older_brand, newer_brand ])
      expect(brands.first.association(:audiences)).not_to be_loaded
    end
  end
end
