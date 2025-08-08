require 'rails_helper'

RSpec.describe Api::V1::ApiTokensController, type: :request do
  let(:user) { create(:user) }

  before do
    # Mock validation service for all tests
    allow_any_instance_of(ApiTokenValidatorService).to receive(:call)
      .and_return({ valid: true })

    # Mock authentication for API testing by defining methods on the controller class
    Api::V1::ApiTokensController.class_eval do
      def authenticate_user!
        # Mocked - always authenticates
      end

      def current_user
        @current_user ||= User.find_by(email: 'test@example.com') || FactoryBot.create(:user)
      end
    end

    # Ensure we have a user that matches our test user
    allow_any_instance_of(Api::V1::ApiTokensController).to receive(:current_user).and_return(user)
  end

  describe 'GET /api/v1/api_tokens' do
    let!(:api_token1) { create(:api_token, :openai, user: user, mode: 'production') }
    let!(:api_token2) { create(:api_token, :heygen, user: user, mode: 'production') }

    it 'returns all user api tokens' do
      get '/api/v1/api_tokens'
      expect(response).to have_http_status(:success)

      json_response = JSON.parse(response.body)
      expect(json_response.length).to eq(2)
      expect(json_response.first).to include('id', 'provider', 'mode', 'valid')
      expect(json_response.first).not_to include('encrypted_token')
    end

    it 'does not return other users tokens' do
      other_user = create(:user)
      create(:api_token, user: other_user)

      get '/api/v1/api_tokens'
      json_response = JSON.parse(response.body)
      expect(json_response.length).to eq(2)
    end
  end

  describe 'GET /api/v1/api_tokens/:id' do
    let(:api_token) { create(:api_token, user: user) }

    it 'returns the api token' do
      get "/api/v1/api_tokens/#{api_token.id}"
      expect(response).to have_http_status(:success)

      json_response = JSON.parse(response.body)
      expect(json_response['id']).to eq(api_token.id)
      expect(json_response).not_to include('encrypted_token')
    end

    it 'returns 404 for non-existent token' do
      get "/api/v1/api_tokens/99999"
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 for other users token' do
      other_user = create(:user)
      other_token = create(:api_token, user: other_user)

      get "/api/v1/api_tokens/#{other_token.id}"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/api_tokens' do
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
        post '/api/v1/api_tokens', params: valid_params
      }.to change(ApiToken, :count).by(1)

      expect(response).to have_http_status(:created)
      json_response = JSON.parse(response.body)
      expect(json_response['provider']).to eq('openai')
      expect(json_response).not_to include('encrypted_token')
    end

    it 'returns errors for invalid params' do
      invalid_params = valid_params.deep_merge(api_token: { provider: 'invalid' })

      post '/api/v1/api_tokens', params: invalid_params
      expect(response).to have_http_status(:unprocessable_entity)

      json_response = JSON.parse(response.body)
      expect(json_response).to have_key('errors')
    end

    it 'associates token with current user' do
      post '/api/v1/api_tokens', params: valid_params

      token = ApiToken.last
      expect(token.user).to eq(user)
    end

    context 'with invalid token' do
      before do
        allow_any_instance_of(ApiTokenValidatorService).to receive(:call)
          .and_return({ valid: false, error: 'Invalid API key' })
      end

      it 'returns 422 with validation error' do
        expect {
          post '/api/v1/api_tokens', params: valid_params
        }.not_to change(ApiToken, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']['encrypted_token']).to be_present
      end
    end
  end

  describe 'PATCH /api/v1/api_tokens/:id' do
    let(:api_token) { create(:api_token, user: user, mode: 'test') }
    let(:update_params) do
      {
        api_token: { mode: 'production' }
      }
    end

    before do
      allow_any_instance_of(ApiTokenValidatorService).to receive(:call)
        .and_return({ valid: true })
    end

    it 'updates the api token' do
      patch "/api/v1/api_tokens/#{api_token.id}", params: update_params
      expect(response).to have_http_status(:success)

      api_token.reload
      expect(api_token.mode).to eq('production')
    end

    it 'returns errors for invalid updates' do
      invalid_params = update_params.deep_merge(api_token: { provider: 'invalid' })

      patch "/api/v1/api_tokens/#{api_token.id}", params: invalid_params
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns 404 for other users token' do
      other_user = create(:user)
      other_token = create(:api_token, user: other_user)

      patch "/api/v1/api_tokens/#{other_token.id}", params: { api_token: { mode: 'production' } }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE /api/v1/api_tokens/:id' do
    let(:api_token) { create(:api_token, user: user) }

    it 'destroys the api token' do
      delete "/api/v1/api_tokens/#{api_token.id}"
      expect(response).to have_http_status(:no_content)

      expect { api_token.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'returns 404 for other users token' do
      other_user = create(:user)
      other_token = create(:api_token, user: other_user)

      delete "/api/v1/api_tokens/#{other_token.id}"
      expect(response).to have_http_status(:not_found)
    end
  end

  context 'when not authenticated' do
    before do
      # Mock authentication to simulate unauthenticated behavior
      allow_any_instance_of(Api::V1::ApiTokensController).to receive(:current_user).and_return(nil)
      allow_any_instance_of(Api::V1::ApiTokensController).to receive(:authenticate_user!) do |controller|
        controller.redirect_to '/users/sign_in'
      end
    end

    it 'requires authentication for all actions' do
      get '/api/v1/api_tokens'
      expect(response).to have_http_status(:redirect)
    end
  end
end
