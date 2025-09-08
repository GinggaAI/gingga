require 'rails_helper'

RSpec.describe SettingsController, type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user, scope: :user
  end

  describe 'GET #show' do
    it 'renders successfully' do
      get settings_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('API Integrations Overview')
    end
  end

  describe 'PATCH #update' do
    context 'with valid heygen api key' do
      it 'saves the API key and redirects with success message' do
        # Mock the API token validator to return success
        allow(ApiTokenValidatorService).to receive_message_chain(:new, :call).and_return({ valid: true })

        patch settings_path, params: { heygen_api_key: 'test_api_key_123', mode: 'production' }

        expect(response).to redirect_to(settings_path)

        # Verify token was saved
        api_token = user.reload.api_tokens.find_by(provider: 'heygen', mode: 'production')
        expect(api_token).to be_present
        expect(api_token.encrypted_token).to eq('test_api_key_123')

        # Follow redirect and check for success messages (in any form)
        follow_redirect!
        expect(response.body).to match(/success|saved|exitosamente/i)
      end
    end

    context 'with empty api key' do
      it 'redirects with error message' do
        patch settings_path, params: { heygen_api_key: '', mode: 'production' }

        expect(response).to redirect_to(settings_path)
        follow_redirect!

        expect(response.body).to include('empty')
      end
    end
  end

  describe 'POST #validate_heygen_api' do
    let!(:api_token) do
      token = build(:api_token, :heygen, user: user, is_valid: true)
      token.save(validate: false)
      token
    end

    context 'when validation succeeds' do
      it 'redirects with success message' do
        # Mock the ValidateAndSyncService to return success with group message
        mock_result = OpenStruct.new(
          success?: true,
          data: {
            synchronized_count: 5,
            message_key: 'settings.heygen.group_validation_success'
          }
        )
        allow(Heygen::ValidateAndSyncService).to receive_message_chain(:new, :call).and_return(mock_result)

        post validate_heygen_api_settings_path

        expect(response).to redirect_to(settings_path)
        follow_redirect!

        expect(response.body).to include('HeyGen group validation successful! 5 avatars synchronized from specific group.')
      end
    end

    context 'when validation fails' do
      it 'redirects with error message' do
        # Mock the synchronize service to return failure
        mock_result = OpenStruct.new(success?: false, error: 'Invalid API key')
        allow(Heygen::SynchronizeAvatarsService).to receive_message_chain(:new, :call).and_return(mock_result)

        post validate_heygen_api_settings_path

        expect(response).to redirect_to(settings_path)
        follow_redirect!

        expect(response.body).to include('HeyGen API validation failed:')
      end
    end
  end

  describe 'content duplication check' do
    it 'should not have duplicated content after form submissions' do
      # First get the page
      get settings_path
      original_content = response.body
      original_api_sections = original_content.scan(/API Integrations Overview/).length

      # Submit a form
      patch settings_path, params: { heygen_api_key: 'test_key', mode: 'production' }
      follow_redirect!

      updated_content = response.body
      updated_api_sections = updated_content.scan(/API Integrations Overview/).length

      # Should have the same number of API Integration sections (no duplication)
      expect(updated_api_sections).to eq(original_api_sections)
      expect(updated_api_sections).to eq(1)
    end
  end
end
