require 'rails_helper'

RSpec.describe SettingsPresenter do
  let(:user) { create(:user) }
  let(:params) { {} }
  let(:presenter) { described_class.new(user, params) }

  before do
    # Mock the API token validation service to prevent actual API calls in tests
    allow(ApiTokenValidatorService).to receive_message_chain(:new, :call).and_return({ valid: true })
  end

  describe '#heygen_token' do
    context 'when user has no HeyGen token' do
      it 'returns nil' do
        expect(presenter.heygen_token).to be_nil
      end
    end

    context 'when user has a valid HeyGen token' do
      let!(:api_token) { create(:api_token, :heygen, user: user, is_valid: true) }

      it 'returns the token' do
        expect(presenter.heygen_token).to eq(api_token)
      end
    end
  end

  describe '#heygen_token_value' do
    context 'when user has no HeyGen token' do
      it 'returns nil' do
        expect(presenter.heygen_token_value).to be_nil
      end
    end

    context 'when user has a token with no encrypted value' do
      let!(:api_token) do
        token = build(:api_token, :heygen, user: user, encrypted_token: 'placeholder')
        token.save(validate: false)  # Skip validation to allow nil encrypted_token
        token.update_column(:encrypted_token, nil)
        token
      end

      it 'returns nil' do
        expect(presenter.heygen_token_value).to be_nil
      end
    end

    context 'when user has a token with encrypted value' do
      let!(:api_token) { create(:api_token, :heygen, user: user, encrypted_token: 'test_key_123') }

      it 'returns the encrypted token value' do
        expect(presenter.heygen_token_value).to eq('test_key_123')
      end
    end
  end

  describe '#heygen_group_url_value' do
    context 'when user has no HeyGen token' do
      it 'returns nil' do
        expect(presenter.heygen_group_url_value).to be_nil
      end
    end

    context 'when user has a token with no group URL' do
      let!(:api_token) { create(:api_token, :heygen, user: user, group_url: nil) }

      it 'returns nil' do
        expect(presenter.heygen_group_url_value).to be_nil
      end
    end

    context 'when user has a token with group URL' do
      let!(:api_token) { create(:api_token, :heygen, user: user, group_url: 'https://app.heygen.com/avatars?groupId=123') }

      it 'returns the group URL value' do
        expect(presenter.heygen_group_url_value).to eq('https://app.heygen.com/avatars?groupId=123')
      end
    end
  end

  describe '#show_group_url_field?' do
    context 'when HeyGen is configured' do
      let!(:api_token) { create(:api_token, :heygen, user: user, is_valid: true) }

      it 'returns true' do
        expect(presenter.show_group_url_field?).to be true
      end
    end

    context 'when HeyGen is not configured' do
      it 'returns true (always show group URL field alongside API key)' do
        expect(presenter.show_group_url_field?).to be true
      end
    end
  end

  describe '#heygen_configured?' do
    context 'when user has no HeyGen token' do
      it 'returns false' do
        expect(presenter.heygen_configured?).to be false
      end
    end

    context 'when user has invalid HeyGen token' do
      let!(:api_token) do
        token = build(:api_token, :heygen, user: user)
        token.save(validate: false)  # Skip validation
        token.update_column(:is_valid, false)
        token
      end

      it 'returns false' do
        expect(presenter.heygen_configured?).to be false
      end
    end

    context 'when user has valid HeyGen token' do
      let!(:api_token) { create(:api_token, :heygen, user: user, is_valid: true) }

      it 'returns true' do
        expect(presenter.heygen_configured?).to be true
      end
    end
  end

  describe '#heygen_configuration_status' do
    context 'when HeyGen is configured' do
      let!(:api_token) { create(:api_token, :heygen, user: user, is_valid: true) }

      it 'returns "Configured"' do
        expect(presenter.heygen_configuration_status).to eq('Configured')
      end
    end

    context 'when HeyGen is not configured' do
      it 'returns "Not configured"' do
        expect(presenter.heygen_configuration_status).to eq('Not configured')
      end
    end
  end

  describe '#heygen_status_class' do
    context 'when HeyGen is configured' do
      let!(:api_token) { create(:api_token, :heygen, user: user, is_valid: true) }

      it 'returns green status class' do
        expect(presenter.heygen_status_class).to include('bg-green-100 text-green-700')
      end
    end

    context 'when HeyGen is not configured' do
      it 'returns secondary status class' do
        expect(presenter.heygen_status_class).to include('bg-secondary text-secondary-foreground')
      end
    end
  end

  describe '#show_validate_button?' do
    context 'when HeyGen is configured' do
      let!(:api_token) { create(:api_token, :heygen, user: user, is_valid: true) }

      it 'returns true' do
        expect(presenter.show_validate_button?).to be true
      end
    end

    context 'when HeyGen is not configured' do
      it 'returns false' do
        expect(presenter.show_validate_button?).to be false
      end
    end
  end

  describe '#show_disabled_validate_button?' do
    context 'when HeyGen is configured' do
      let!(:api_token) { create(:api_token, :heygen, user: user, is_valid: true) }

      it 'returns false' do
        expect(presenter.show_disabled_validate_button?).to be false
      end
    end

    context 'when HeyGen is not configured' do
      it 'returns true' do
        expect(presenter.show_disabled_validate_button?).to be true
      end
    end
  end

  describe '#validate_button_class' do
    it 'returns the active validate button CSS classes' do
      expect(presenter.validate_button_class).to include('bg-[#3AC8FF]')
    end
  end

  describe '#disabled_validate_button_class' do
    it 'returns the disabled validate button CSS classes' do
      expect(presenter.disabled_validate_button_class).to include('bg-gray-400')
    end
  end

  describe '#disabled_validate_button_title' do
    it 'returns the tooltip message' do
      expect(presenter.disabled_validate_button_title).to eq('Save API key first to enable validation')
    end
  end

  describe 'flash message methods' do
    context 'with flash messages' do
      let(:params) { { flash: { notice: 'Success!', alert: 'Error!' } } }

      describe '#show_notice?' do
        it 'returns true when notice is present' do
          expect(presenter.show_notice?).to be true
        end
      end

      describe '#show_alert?' do
        it 'returns true when alert is present' do
          expect(presenter.show_alert?).to be true
        end
      end

      describe '#notice_message' do
        it 'returns the notice message' do
          expect(presenter.notice_message).to eq('Success!')
        end
      end

      describe '#alert_message' do
        it 'returns the alert message' do
          expect(presenter.alert_message).to eq('Error!')
        end
      end
    end

    context 'without flash messages' do
      describe '#show_notice?' do
        it 'returns false when no notice' do
          expect(presenter.show_notice?).to be false
        end
      end

      describe '#show_alert?' do
        it 'returns false when no alert' do
          expect(presenter.show_alert?).to be false
        end
      end
    end
  end

  describe 'API integration stats' do
    describe '#active_connections_count' do
      context 'when user has no API tokens' do
        it 'returns 0' do
          expect(presenter.active_connections_count).to eq(0)
        end
      end

      context 'when user has valid API tokens' do
        let!(:heygen_token) { create(:api_token, :heygen, user: user, is_valid: true) }
        let!(:openai_token) { create(:api_token, user: user, provider: 'openai', is_valid: true) }
        let!(:invalid_token) do
          token = build(:api_token, user: user, provider: 'kling')
          token.save(validate: false)
          token.update_column(:is_valid, false)
          token
        end

        it 'returns count of valid tokens only' do
          expect(presenter.active_connections_count).to eq(2)
        end
      end
    end

    describe '#available_services_count' do
      it 'returns 3' do
        expect(presenter.available_services_count).to eq(3)
      end
    end

    describe '#test_mode_count' do
      context 'when user has no test mode tokens' do
        it 'returns 0' do
          expect(presenter.test_mode_count).to eq(0)
        end
      end

      context 'when user has test mode tokens' do
        let!(:test_token1) { create(:api_token, user: user, provider: 'heygen', mode: 'test') }
        let!(:test_token2) { create(:api_token, user: user, provider: 'openai', mode: 'test') }
        let!(:prod_token) { create(:api_token, user: user, provider: 'kling', mode: 'production') }

        it 'returns count of test mode tokens' do
          expect(presenter.test_mode_count).to eq(2)
        end
      end
    end
  end
end
