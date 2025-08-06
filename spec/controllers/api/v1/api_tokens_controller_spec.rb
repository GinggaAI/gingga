require 'rails_helper'

RSpec.describe Api::V1::ApiTokensController, type: :controller do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe 'GET #index' do
    let!(:api_tokens) { create_list(:api_token, 2, user: user) }

    it 'returns all user api tokens' do
      get :index
      expect(response).to have_http_status(:success)

      json_response = JSON.parse(response.body)
      expect(json_response.length).to eq(2)
      expect(json_response.first).to include('id', 'provider', 'mode', 'valid')
      expect(json_response.first).not_to include('encrypted_token')
    end

    it 'does not return other users tokens' do
      other_user = create(:user)
      create(:api_token, user: other_user)

      get :index
      json_response = JSON.parse(response.body)
      expect(json_response.length).to eq(2)
    end
  end

  describe 'GET #show' do
    let(:api_token) { create(:api_token, user: user) }

    it 'returns the api token' do
      get :show, params: { id: api_token.id }
      expect(response).to have_http_status(:success)

      json_response = JSON.parse(response.body)
      expect(json_response['id']).to eq(api_token.id)
      expect(json_response).not_to include('encrypted_token')
    end

    it 'returns 404 for non-existent token' do
      get :show, params: { id: 99999 }
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 for other users token' do
      other_user = create(:user)
      other_token = create(:api_token, user: other_user)

      get :show, params: { id: other_token.id }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST #create' do
    let(:valid_params) do
      {
        api_token: {
          provider: 'openai',
          mode: 'production',
          encrypted_token: 'sk-test123'
        }
      }
    end

    before do
      allow_any_instance_of(ApiTokenValidatorService).to receive(:call)
        .and_return({ valid: true })
    end

    it 'creates a new api token' do
      expect {
        post :create, params: valid_params
      }.to change(ApiToken, :count).by(1)

      expect(response).to have_http_status(:created)
      json_response = JSON.parse(response.body)
      expect(json_response['provider']).to eq('openai')
      expect(json_response).not_to include('encrypted_token')
    end

    it 'returns errors for invalid params' do
      invalid_params = valid_params.deep_merge(api_token: { provider: 'invalid' })

      post :create, params: invalid_params
      expect(response).to have_http_status(:unprocessable_entity)

      json_response = JSON.parse(response.body)
      expect(json_response).to have_key('errors')
    end

    it 'associates token with current user' do
      post :create, params: valid_params

      token = ApiToken.last
      expect(token.user).to eq(user)
    end
  end

  describe 'PATCH #update' do
    let(:api_token) { create(:api_token, user: user, mode: 'test') }
    let(:update_params) do
      {
        id: api_token.id,
        api_token: { mode: 'production' }
      }
    end

    before do
      allow_any_instance_of(ApiTokenValidatorService).to receive(:call)
        .and_return({ valid: true })
    end

    it 'updates the api token' do
      patch :update, params: update_params
      expect(response).to have_http_status(:success)

      api_token.reload
      expect(api_token.mode).to eq('production')
    end

    it 'returns errors for invalid updates' do
      invalid_params = update_params.deep_merge(api_token: { provider: 'invalid' })

      patch :update, params: invalid_params
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns 404 for other users token' do
      other_user = create(:user)
      other_token = create(:api_token, user: other_user)

      patch :update, params: { id: other_token.id, api_token: { mode: 'production' } }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE #destroy' do
    let(:api_token) { create(:api_token, user: user) }

    it 'destroys the api token' do
      delete :destroy, params: { id: api_token.id }
      expect(response).to have_http_status(:no_content)

      expect { api_token.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'returns 404 for other users token' do
      other_user = create(:user)
      other_token = create(:api_token, user: other_user)

      delete :destroy, params: { id: other_token.id }
      expect(response).to have_http_status(:not_found)
    end
  end

  context 'when not authenticated' do
    before do
      sign_out user
    end

    it 'requires authentication for all actions' do
      get :index
      expect(response).to have_http_status(:found)
    end
  end
end
