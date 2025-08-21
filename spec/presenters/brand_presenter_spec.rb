require 'rails_helper'

RSpec.describe BrandPresenter do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, name: 'Test Brand', user: user) }
  let(:presenter) { described_class.new(brand) }

  describe '#name' do
    context 'when brand has a name' do
      it 'returns the brand name' do
        expect(presenter.name).to eq('Test Brand')
      end
    end

    context 'when brand has no name' do
      let(:brand) { build(:brand, name: nil, user: user) }

      it 'returns default name' do
        expect(presenter.name).to eq('Untitled Brand')
      end
    end

    context 'when brand has empty name' do
      let(:brand) { build(:brand, name: '', user: user) }

      it 'returns default name' do
        expect(presenter.name).to eq('Untitled Brand')
      end
    end
  end

  describe '#audiences' do
    it 'returns audiences ordered by creation date' do
      audience1 = create(:audience, brand: brand)
      audience2 = create(:audience, brand: brand)

      expect(presenter.audiences).to eq([ audience1, audience2 ])
    end

    it 'returns empty collection when no audiences' do
      expect(presenter.audiences).to be_empty
    end
  end

  describe '#products' do
    it 'returns products ordered by creation date' do
      product1 = create(:product, brand: brand, name: 'Product 1')
      product2 = create(:product, brand: brand, name: 'Product 2')

      expect(presenter.products).to eq([ product1, product2 ])
    end

    it 'returns empty collection when no products' do
      expect(presenter.products).to be_empty
    end
  end

  describe '#brand_channels' do
    it 'returns channels ordered by priority then creation date' do
      channel1 = create(:brand_channel, brand: brand, platform: 'instagram', priority: 2)
      channel2 = create(:brand_channel, brand: brand, platform: 'tiktok', priority: 1)

      expect(presenter.brand_channels).to eq([ channel2, channel1 ])
    end

    it 'returns empty collection when no channels' do
      expect(presenter.brand_channels).to be_empty
    end
  end

  describe 'has_* methods' do
    describe '#has_audiences?' do
      context 'when brand has audiences' do
        before { create(:audience, brand: brand) }

        it 'returns true' do
          expect(presenter.has_audiences?).to be true
        end
      end

      context 'when brand has no audiences' do
        it 'returns false' do
          expect(presenter.has_audiences?).to be false
        end
      end
    end

    describe '#has_products?' do
      context 'when brand has products' do
        before { create(:product, brand: brand, name: 'Test Product') }

        it 'returns true' do
          expect(presenter.has_products?).to be true
        end
      end

      context 'when brand has no products' do
        it 'returns false' do
          expect(presenter.has_products?).to be false
        end
      end
    end

    describe '#has_brand_channels?' do
      context 'when brand has channels' do
        before { create(:brand_channel, brand: brand) }

        it 'returns true' do
          expect(presenter.has_brand_channels?).to be true
        end
      end

      context 'when brand has no channels' do
        it 'returns false' do
          expect(presenter.has_brand_channels?).to be false
        end
      end
    end
  end

  describe '#missing_requirements' do
    context 'when all requirements are met' do
      before do
        create(:audience, brand: brand)
        create(:product, brand: brand, name: 'Test Product')
        create(:brand_channel, brand: brand)
      end

      it 'returns empty array' do
        expect(presenter.missing_requirements).to be_empty
      end
    end

    context 'when some requirements are missing' do
      before { create(:audience, brand: brand) }

      it 'returns array of missing requirements' do
        expect(presenter.missing_requirements).to contain_exactly('products', 'brand_channels')
      end
    end

    context 'when all requirements are missing' do
      it 'returns all requirements' do
        expect(presenter.missing_requirements).to contain_exactly('audiences', 'products', 'brand_channels')
      end
    end
  end

  describe '#strategy_ready?' do
    context 'when all requirements are met' do
      before do
        create(:audience, brand: brand)
        create(:product, brand: brand, name: 'Test Product')
        create(:brand_channel, brand: brand)
      end

      it 'returns true' do
        expect(presenter.strategy_ready?).to be true
      end
    end

    context 'when requirements are missing' do
      it 'returns false' do
        expect(presenter.strategy_ready?).to be false
      end
    end
  end

  describe '#strategy_readiness_message' do
    context 'when strategy ready' do
      before do
        create(:audience, brand: brand)
        create(:product, brand: brand, name: 'Test Product')
        create(:brand_channel, brand: brand)
      end

      it 'returns success message' do
        expect(presenter.strategy_readiness_message).to eq('Your brand is ready for strategy creation!')
      end
    end

    context 'when not strategy ready' do
      before { create(:audience, brand: brand) }

      it 'returns requirements message' do
        expect(presenter.strategy_readiness_message).to eq('Please add products, brand_channels before creating a strategy.')
      end
    end
  end

  describe '#audience_demographics_summary' do
    context 'when no audiences' do
      it 'returns no audiences message' do
        expect(presenter.audience_demographics_summary).to eq('No audiences defined')
      end
    end

    context 'when audiences exist with demographics' do
      before do
        create(:audience, brand: brand, demographic_profile: {
          'age_range' => '25-35',
          'location' => 'United States'
        })
        create(:audience, brand: brand, demographic_profile: {
          'age_range' => '18-24',
          'location' => 'Canada'
        })
      end

      it 'returns demographic summary' do
        expect(presenter.audience_demographics_summary).to eq('25-35, 18-24 years old from United States, Canada')
      end
    end

    context 'when audiences exist without demographics' do
      before { create(:audience, brand: brand, demographic_profile: {}) }

      it 'returns empty summary' do
        expect(presenter.audience_demographics_summary).to eq('')
      end
    end
  end

  describe '#products_summary' do
    context 'when no products' do
      it 'returns no products message' do
        expect(presenter.products_summary).to eq('No products defined')
      end
    end

    context 'when one product' do
      before { create(:product, brand: brand, name: 'Single Product') }

      it 'returns product name' do
        expect(presenter.products_summary).to eq('Single Product')
      end
    end

    context 'when two products' do
      before do
        create(:product, brand: brand, name: 'Product A')
        create(:product, brand: brand, name: 'Product B')
      end

      it 'returns both product names' do
        expect(presenter.products_summary).to eq('Product A and Product B')
      end
    end

    context 'when more than two products' do
      before do
        create(:product, brand: brand, name: 'Product A')
        create(:product, brand: brand, name: 'Product B')
        create(:product, brand: brand, name: 'Product C')
      end

      it 'returns first product and count' do
        expect(presenter.products_summary).to eq('Product A and 2 more')
      end
    end
  end

  describe '#channels_summary' do
    context 'when no channels' do
      it 'returns no channels message' do
        expect(presenter.channels_summary).to eq('No channels configured')
      end
    end

    context 'when channels exist' do
      before do
        create(:brand_channel, brand: brand, platform: 'instagram')
        create(:brand_channel, brand: brand, platform: 'tiktok')
      end

      it 'returns capitalized platform names' do
        expect(presenter.channels_summary).to eq('Instagram, Tiktok')
      end
    end
  end

  describe 'view logic methods' do
    let(:brands_collection) { [ create(:brand, user: user), create(:brand, user: user) ] }
    let(:notice) { 'Brand updated successfully!' }
    let(:presenter_with_params) { described_class.new(brand, { notice: notice, brands_collection: brands_collection }) }

    describe '#show_notice?' do
      context 'when notice is present' do
        it 'returns true' do
          expect(presenter_with_params.show_notice?).to be true
        end
      end

      context 'when notice is blank' do
        let(:presenter_without_notice) { described_class.new(brand, { notice: '', brands_collection: brands_collection }) }

        it 'returns false' do
          expect(presenter_without_notice.show_notice?).to be false
        end
      end

      context 'when notice is nil' do
        let(:presenter_without_notice) { described_class.new(brand, { notice: nil, brands_collection: brands_collection }) }

        it 'returns false' do
          expect(presenter_without_notice.show_notice?).to be false
        end
      end
    end

    describe '#notice_message' do
      it 'returns the notice message' do
        expect(presenter_with_params.notice_message).to eq('Brand updated successfully!')
      end
    end

    describe '#show_brands_selector?' do
      context 'when brands collection has items' do
        it 'returns true' do
          expect(presenter_with_params.show_brands_selector?).to be true
        end
      end

      context 'when brands collection is empty' do
        let(:presenter_without_brands) { described_class.new(brand, { notice: notice, brands_collection: [] }) }

        it 'returns false' do
          expect(presenter_without_brands.show_brands_selector?).to be false
        end
      end

      context 'when brands collection is nil' do
        let(:presenter_without_brands) { described_class.new(brand, { notice: notice, brands_collection: nil }) }

        it 'returns false' do
          expect(presenter_without_brands.show_brands_selector?).to be false
        end
      end
    end

    describe '#brands_collection' do
      context 'when brands collection is provided' do
        it 'returns the brands collection' do
          expect(presenter_with_params.brands_collection).to eq(brands_collection)
        end
      end

      context 'when brands collection is not provided' do
        it 'returns empty array' do
          expect(presenter.brands_collection).to eq([])
        end
      end
    end

    describe '#show_validation_errors?' do
      context 'when brand has validation errors' do
        before do
          brand.errors.add(:name, 'is required')
        end

        it 'returns true' do
          expect(presenter.show_validation_errors?).to be true
        end
      end

      context 'when brand has no validation errors' do
        it 'returns false' do
          expect(presenter.show_validation_errors?).to be false
        end
      end
    end

    describe '#validation_error_messages' do
      before do
        brand.errors.add(:name, 'is required')
        brand.errors.add(:industry, 'must be selected')
      end

      it 'returns full error messages' do
        expect(presenter.validation_error_messages).to contain_exactly(
          'Name is required',
          'Industry must be selected'
        )
      end
    end
  end
end
