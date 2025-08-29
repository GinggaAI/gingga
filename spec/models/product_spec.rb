require 'rails_helper'

RSpec.describe Product, type: :model do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }

  describe 'associations' do
    it { should belong_to(:brand) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }

    describe 'name uniqueness' do
      let!(:existing_product) { create(:product, brand: brand, name: 'Test Product') }

      it 'validates uniqueness of name within brand scope' do
        new_product = build(:product, brand: brand, name: 'Test Product')
        expect(new_product).not_to be_valid
        expect(new_product.errors[:name]).to include("has already been taken")
      end

      it 'allows same name for different brands' do
        other_brand = create(:brand, user: user)
        new_product = build(:product, brand: other_brand, name: 'Test Product')
        expect(new_product).to be_valid
      end
    end
  end

  describe 'creation' do
    it 'can be created with valid attributes' do
      product = Product.new(
        brand: brand,
        name: 'Test Product',
        description: 'A test product description'
      )

      expect(product).to be_valid
      expect { product.save! }.not_to raise_error
    end

    it 'cannot be created without a name' do
      product = build(:product, brand: brand, name: nil)
      expect(product).not_to be_valid
      expect(product.errors[:name]).to include("can't be blank")
    end

    it 'cannot be created without a brand' do
      product = build(:product, brand: nil)
      expect(product).not_to be_valid
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      product = build(:product, brand: brand)
      expect(product).to be_valid
    end
  end
end
