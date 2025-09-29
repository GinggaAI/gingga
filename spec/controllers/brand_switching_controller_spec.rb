require 'rails_helper'

RSpec.describe "BrandSwitchingController", type: :request do
  let(:user) { create(:user) }

  before { sign_in user, scope: :user }

  describe 'POST #create' do
    let!(:brand1) { create(:brand, user: user, name: 'First Brand') }
    let!(:brand2) { create(:brand, user: user, name: 'Second Brand') }

    before { user.update(last_brand: brand1) }

    context 'when switching to a valid user brand' do
      it 'successfully switches to the selected brand' do
        post switch_brand_path, params: { brand_id: brand2.id }

        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['brand']['id']).to eq(brand2.id)
        expect(json_response['brand']['name']).to eq('Second Brand')
        expect(json_response['brand']['slug']).to eq(brand2.slug)
      end

      it 'updates user current brand' do
        post switch_brand_path, params: { brand_id: brand2.id }

        expect(user.reload.current_brand).to eq(brand2)
      end
    end

    context 'when brand_id is blank' do
      it 'returns error response' do
        post switch_brand_path, params: { brand_id: '' }

        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['error']).to eq("Brand not found or not accessible")
      end
    end

    context 'when brand does not belong to user' do
      it 'returns error response' do
        # Ensure we have a brand that definitely doesn't belong to the test user
        other_user = create(:user, email: 'other_test@example.com')
        brand_for_other_user = create(:brand, user: other_user, name: 'Other Brand')

        post switch_brand_path, params: { brand_id: brand_for_other_user.id }

        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['error']).to eq("Brand not found or not accessible")
      end

      it 'does not change user current brand' do
        # Ensure we have a brand that definitely doesn't belong to the test user
        other_user = create(:user, email: 'another_test@example.com')
        brand_for_other_user = create(:brand, user: other_user, name: 'Another Brand')

        original_brand = user.current_brand
        post switch_brand_path, params: { brand_id: brand_for_other_user.id }

        expect(user.reload.current_brand).to eq(original_brand)
      end
    end

    context 'when brand_id does not exist' do
      it 'returns error response' do
        post switch_brand_path, params: { brand_id: 99999 }

        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['error']).to eq("Brand not found or not accessible")
      end
    end

    context 'when service fails' do
      before do
        allow_any_instance_of(Brands::SelectionService).to receive(:call).and_return(
          { success: false, data: nil, error: "Service error" }
        )
      end

      it 'returns error response' do
        post switch_brand_path, params: { brand_id: brand2.id }

        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['error']).to eq("Service error")
      end
    end

    context 'when user is not authenticated' do
      before { sign_out user }

      it 'redirects to sign in' do
        post switch_brand_path, params: { brand_id: brand2.id }

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end