# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ui::GlobalBrandSwitcherComponent, type: :component do
  let(:user) { create(:user) }
  let(:brand1) { create(:brand, user: user, name: 'Brand One', slug: 'brand-one') }
  let(:brand2) { create(:brand, user: user, name: 'Brand Two', slug: 'brand-two') }

  describe '#initialize' do
    context 'with current_brand parameter' do
      it 'uses the provided current_brand' do
        component = described_class.new(current_user: user, current_brand: brand1)
        expect(component.instance_variable_get(:@current_brand)).to eq(brand1)
      end
    end

    context 'without current_brand parameter' do
      it 'uses current_user.current_brand' do
        user.update(last_brand: brand1)
        component = described_class.new(current_user: user)
        expect(component.instance_variable_get(:@current_brand)).to eq(brand1)
      end
    end
  end

  describe '#render' do
    context 'when user has brands' do
      before do
        brand1
        brand2
        user.update(last_brand: brand1)
      end

      it 'renders the brand switcher' do
        render_inline(described_class.new(current_user: user))

        expect(page).to have_content('Brand One')
      end

      it 'lists all user brands' do
        render_inline(described_class.new(current_user: user))

        expect(page).to have_content('Brand One')
        expect(page).to have_content('Brand Two')
      end
    end

    context 'when user has no brands' do
      it 'shows create brand CTA' do
        render_inline(described_class.new(current_user: user))

        # When user has no brands, should show create brand message
        expect(page).to have_content('Create Your First Brand')
      end
    end
  end

  describe 'private methods' do
    let(:component) { described_class.new(current_user: user) }

    before do
      brand1
      brand2
      render_inline(component)
    end

    describe '#user_brands' do
      it 'returns user brands ordered by created_at' do
        brands = component.send(:user_brands)
        expect(brands).to eq([ brand1, brand2 ])
      end

      it 'memoizes the result' do
        brands1 = component.send(:user_brands)
        brands2 = component.send(:user_brands)
        expect(brands1.object_id).to eq(brands2.object_id)
      end
    end

    describe '#has_brands?' do
      it 'returns true when user has brands' do
        expect(component.send(:has_brands?)).to be true
      end

      it 'returns false when user has no brands' do
        user.brands.destroy_all
        component_no_brands = described_class.new(current_user: user)
        render_inline(component_no_brands)
        expect(component_no_brands.send(:has_brands?)).to be false
      end
    end

    describe '#current_brand_name' do
      it 'returns brand name when current_brand exists' do
        user.update(last_brand: brand1)
        component_with_brand = described_class.new(current_user: user)
        render_inline(component_with_brand)
        expect(component_with_brand.send(:current_brand_name)).to eq('Brand One')
      end

      it 'returns no_brand_selected translation when no current_brand' do
        user.brands.destroy_all
        user.update(last_brand: nil)
        component_no_brand = described_class.new(current_user: user, current_brand: nil)
        render_inline(component_no_brand)
        expect(component_no_brand.send(:current_brand_name)).to eq(I18n.t('brands.no_brand_selected'))
      end
    end

    describe '#show_create_brand_cta?' do
      it 'returns true when user has no brands' do
        user.brands.destroy_all
        component_no_brands = described_class.new(current_user: user)
        render_inline(component_no_brands)
        expect(component_no_brands.send(:show_create_brand_cta?)).to be true
      end

      it 'returns false when user has brands' do
        expect(component.send(:show_create_brand_cta?)).to be false
      end
    end
  end
end
