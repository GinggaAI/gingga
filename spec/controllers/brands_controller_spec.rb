require 'rails_helper'

RSpec.describe "BrandsController", type: :request do
  let(:user) { create(:user) }

  before { sign_in user, scope: :user }

  describe 'POST #create' do
    context 'when brand creation is successful' do
      it 'creates a new brand' do
        expect {
          post brand_path
        }.to change(user.brands, :count).by(1)
      end

      it 'redirects to edit brand path with new brand id' do
        post brand_path

        new_brand = user.brands.last
        expect(response).to redirect_to(edit_brand_path(brand_id: new_brand.id))
        expect(flash[:notice]).to eq("New brand created successfully!")
      end

      it 'creates brand with default attributes' do
        post brand_path

        new_brand = user.brands.last
        expect(new_brand.name).to eq("New Brand")
        expect(new_brand.slug).to match(/^brand-\d+$/)
        expect(new_brand.industry).to eq("other")
        expect(new_brand.voice).to eq("professional")
      end
    end

    context 'when brand creation fails' do
      before do
        allow_any_instance_of(Brands::CreationService).to receive(:call).and_return(
          { success: false, data: nil, error: "Failed to create brand" }
        )
      end

      it 'redirects to edit brand path with error' do
        post brand_path

        expect(response).to redirect_to(edit_brand_path)
        expect(flash[:alert]).to eq("Failed to create brand")
      end

      it 'does not create a new brand' do
        expect {
          post brand_path
        }.not_to change(Brand, :count)
      end
    end
  end

  describe 'PATCH #update' do
    let!(:brand1) { create(:brand, user: user, name: 'First Brand') }
    let!(:brand2) { create(:brand, user: user, name: 'Second Brand') }

    context 'when updating a specific brand via brand_id parameter' do
      let(:update_params) {
        {
          brand: {
            name: 'Updated Second Brand',
            industry: 'technology'
          },
          brand_id: brand2.id
        }
      }

      it 'updates the correct brand (not the first one)' do
        patch brand_path, params: update_params

        brand2.reload
        brand1.reload

        expect(brand2.name).to eq('Updated Second Brand')
        expect(brand1.name).to eq('First Brand') # Should remain unchanged
      end

      it 'redirects to edit path with the correct brand_id' do
        patch brand_path, params: update_params

        expect(response).to redirect_to(edit_brand_path(brand_id: brand2.id))
        expect(flash[:notice]).to eq("Brand profile updated successfully!")
      end
    end

    context 'when updating without brand_id parameter (default behavior)' do
      let(:update_params) {
        {
          brand: {
            name: 'Updated First Brand',
            industry: 'technology'
          }
        }
      }

      it 'updates the first brand (default behavior)' do
        first_brand_before_update = user.brands.first

        patch brand_path, params: update_params

        # Reload and verify the first brand was updated
        first_brand_before_update.reload
        expect(first_brand_before_update.name).to eq('Updated First Brand')

        # Ensure the other brand was not updated
        other_brand = user.brands.where.not(id: first_brand_before_update.id).first
        other_brand.reload
        expect(other_brand.name).to_not eq('Updated First Brand')
      end
    end
  end

end
