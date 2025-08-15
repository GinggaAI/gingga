require 'rails_helper'

RSpec.describe Product, type: :model do
  describe 'associations' do
    it { should belong_to(:brand) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }

    describe 'name uniqueness' do
      let(:brand) { create(:brand) }
      let!(:existing_product) { create(:product, brand: brand, name: 'Test Product') }

      it 'validates uniqueness of name within brand scope' do
        new_product = build(:product, brand: brand, name: 'Test Product')
        expect(new_product).not_to be_valid
        expect(new_product.errors[:name]).to include("has already been taken")
      end

      it 'allows same name for different brands' do
        other_brand = create(:brand)
        new_product = build(:product, brand: other_brand, name: 'Test Product')
        expect(new_product).to be_valid
      end
    end
  end
end
