require 'rails_helper'

RSpec.describe ApiIntegrationsController, type: :request do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }

  before do
    sign_in user, scope: :user
    user.update_last_brand(brand)
  end

  describe 'PATCH #update' do
    context 'with heygen provider' do
      context 'with valid api key' do
        it 'saves the API key and redirects with success message' do
          # Mock the API token validator to return success
          allow(ApiTokenValidatorService).to receive_message_chain(:new, :call).and_return({ valid: true })

          patch api_integration_path(provider: 'heygen', brand_slug: brand.slug, locale: :en), params: { heygen_api_key: 'test_api_key_123', mode: 'production' }

          expect(response).to redirect_to(settings_path(brand_slug: brand.slug, locale: :en))

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
          patch api_integration_path(provider: 'heygen', brand_slug: brand.slug, locale: :en), params: { heygen_api_key: '', mode: 'production' }

          expect(response).to redirect_to(settings_path(brand_slug: brand.slug, locale: :en))
          follow_redirect!

          expect(response.body).to include('empty')
        end
      end
    end

    context 'with openai provider' do
      context 'with valid openai api key' do
        it 'saves the API key and redirects with success message' do
          # Mock the API token validator to return success
          allow(ApiTokenValidatorService).to receive_message_chain(:new, :call).and_return({ valid: true })

          patch api_integration_path(provider: 'openai', brand_slug: brand.slug, locale: :en), params: { openai_api_key: 'sk-test-key-123', mode: 'production' }

          expect(response).to redirect_to(settings_path(brand_slug: brand.slug, locale: :en))

          # Verify token was saved
          api_token = brand.reload.api_tokens.find_by(provider: 'openai', mode: 'production')
          expect(api_token).to be_present
          expect(api_token.encrypted_token).to eq('sk-test-key-123')

          # Follow redirect and check for success messages
          follow_redirect!
          expect(response.body).to match(/success|saved|exitosamente/i)
        end
      end

      context 'with empty api key' do
        it 'redirects with error message' do
          patch api_integration_path(provider: 'openai', brand_slug: brand.slug, locale: :en), params: { openai_api_key: '', mode: 'production' }

          expect(response).to redirect_to(settings_path(brand_slug: brand.slug, locale: :en))
          follow_redirect!

          expect(response.body).to include('empty')
        end
      end
    end
  end

  describe 'POST #validate' do
    context 'with heygen provider' do
      let!(:api_token) do
        token = build(:api_token, :heygen, user: user, is_valid: true)
        token.save(validate: false)
        token
      end

      context 'when validation succeeds' do
        it 'redirects with success message' do
          # Mock the ValidateAndSyncService to return success with group message
          mock_result = Struct.new(:success?, :data, :error, keyword_init: true).new(
            success?: true,
            data: {
              synchronized_count: 5,
              message_key: 'settings.heygen.group_validation_success'
            },
            error: nil
          )
          allow(Heygen::ValidateAndSyncService).to receive_message_chain(:new, :call).and_return(mock_result)

          post validate_api_integration_path(provider: 'heygen', brand_slug: brand.slug, locale: :en)

          expect(response).to redirect_to(settings_path(brand_slug: brand.slug, locale: :en))
          follow_redirect!

          expect(response.body).to include('HeyGen group validation successful! 5 avatars synchronized from specific group.')
        end
      end

      context 'when validation fails' do
        it 'redirects with error message' do
          # Mock the synchronize service to return failure
          mock_result = Struct.new(:success?, :data, :error, keyword_init: true).new(
            success?: false,
            data: nil,
            error: 'Invalid API key'
          )
          allow(Heygen::ValidateAndSyncService).to receive_message_chain(:new, :call).and_return(mock_result)

          post validate_api_integration_path(provider: 'heygen', brand_slug: brand.slug, locale: :en)

          expect(response).to redirect_to(settings_path(brand_slug: brand.slug, locale: :en))
          follow_redirect!

          expect(response.body).to include('HeyGen API validation failed:')
        end
      end
    end

    context 'with openai provider' do
      let!(:openai_token) do
        token = build(:api_token, :openai, brand: brand, user: user, is_valid: true)
        token.save(validate: false)
        token
      end

      context 'when validation succeeds' do
        it 'redirects with success message' do
          # Mock the ValidateAndUpdateService to return success
          mock_result = Struct.new(:success?, :data, :error, keyword_init: true).new(
            success?: true,
            data: { message: 'OpenAI API key validated successfully' },
            error: nil
          )
          allow(GinggaOpenAI::ValidateAndUpdateService).to receive_message_chain(:new, :call).and_return(mock_result)

          post validate_api_integration_path(provider: 'openai', brand_slug: brand.slug, locale: :en)

          expect(response).to redirect_to(settings_path(brand_slug: brand.slug, locale: :en))
          follow_redirect!

          expect(response.body).to include('OpenAI API key validated successfully')
        end
      end

      context 'when validation fails' do
        it 'redirects with error message' do
          # Mock the ValidateAndUpdateService to return failure
          mock_result = Struct.new(:success?, :data, :error, keyword_init: true).new(
            success?: false,
            data: nil,
            error: 'Invalid API key'
          )
          allow(GinggaOpenAI::ValidateAndUpdateService).to receive_message_chain(:new, :call).and_return(mock_result)

          post validate_api_integration_path(provider: 'openai', brand_slug: brand.slug, locale: :en)

          expect(response).to redirect_to(settings_path(brand_slug: brand.slug, locale: :en))
          follow_redirect!

          expect(response.body).to include('OpenAI API validation failed:')
        end
      end

      context 'when no token exists' do
        before { openai_token.destroy }

        it 'redirects with error message' do
          post validate_api_integration_path(provider: 'openai', brand_slug: brand.slug, locale: :en)

          expect(response).to redirect_to(settings_path(brand_slug: brand.slug, locale: :en))
          follow_redirect!

          expect(response.body).to include('Please save an OpenAI API key first')
        end
      end
    end
  end
end
