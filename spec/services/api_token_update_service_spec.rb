require 'rails_helper'
require 'ostruct'

RSpec.describe ApiTokenUpdateService, type: :service do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }
  let(:provider) { 'heygen' }
  let(:token_value) { 'test_token_123' }
  let(:mode) { 'production' }

  describe '#call' do
    context 'when creating a new API token' do
      it 'creates a new API token successfully' do
        service = described_class.new(
          user: user,
          brand: brand,
          provider: provider,
          token_value: token_value,
          mode: mode
        )

        # Skip the token validation callback to avoid API calls
        ApiToken.skip_callback(:save, :before, :validate_token_with_provider)

        result = service.call

        ApiToken.set_callback(:save, :before, :validate_token_with_provider)

        expect(result.success?).to be true
        expect(result.data[:api_token]).to be_a(ApiToken)
        expect(result.data[:api_token].provider).to eq(provider)
        expect(result.data[:api_token].encrypted_token).to eq(token_value)
        expect(result.data[:api_token].mode).to eq(mode)
        expect(result.data[:api_token].user).to eq(user)
      end

      it 'handles heygen-specific options' do
        group_url = 'https://app.heygen.com/group/abc123'
        service = described_class.new(
          user: user,
          brand: brand,
          provider: 'heygen',
          token_value: token_value,
          mode: mode,
          group_url: group_url
        )

        # Skip the token validation callback to avoid API calls
        ApiToken.skip_callback(:save, :before, :validate_token_with_provider)

        result = service.call

        ApiToken.set_callback(:save, :before, :validate_token_with_provider)

        expect(result.success?).to be true
        expect(result.data[:api_token].group_url).to eq(group_url)
      end

      it 'ignores empty group_url for heygen' do
        service = described_class.new(
          user: user,
          brand: brand,
          provider: 'heygen',
          token_value: token_value,
          mode: mode,
          group_url: ''
        )

        # Skip the token validation callback to avoid API calls
        ApiToken.skip_callback(:save, :before, :validate_token_with_provider)

        result = service.call

        ApiToken.set_callback(:save, :before, :validate_token_with_provider)

        expect(result.success?).to be true
        expect(result.data[:api_token].group_url).to be_nil
      end
    end

    context 'when updating an existing API token' do
      let!(:existing_token) do
        # Skip the token validation callback to avoid API calls
        ApiToken.skip_callback(:save, :before, :validate_token_with_provider)
        token = create(:api_token, :heygen, user: user, brand: brand, mode: mode, encrypted_token: 'old_token')
        ApiToken.set_callback(:save, :before, :validate_token_with_provider)
        token
      end

      it 'updates the existing token' do
        new_token_value = 'updated_token_456'
        service = described_class.new(
          user: user,
          brand: brand,
          provider: provider,
          token_value: new_token_value,
          mode: mode
        )

        # Skip the token validation callback to avoid API calls
        ApiToken.skip_callback(:save, :before, :validate_token_with_provider)

        result = service.call

        ApiToken.set_callback(:save, :before, :validate_token_with_provider)

        expect(result.success?).to be true
        expect(result.data[:api_token].id).to eq(existing_token.id)
        expect(result.data[:api_token].encrypted_token).to eq(new_token_value)
      end

      it 'updates heygen-specific options' do
        new_group_url = 'https://app.heygen.com/group/xyz789'
        service = described_class.new(
          user: user,
          brand: brand,
          provider: 'heygen',
          token_value: token_value,
          mode: mode,
          group_url: new_group_url
        )

        # Skip the token validation callback to avoid API calls
        ApiToken.skip_callback(:save, :before, :validate_token_with_provider)

        result = service.call

        ApiToken.set_callback(:save, :before, :validate_token_with_provider)

        expect(result.success?).to be true
        expect(result.data[:api_token].group_url).to eq(new_group_url)
      end
    end

    context 'when token value is blank' do
      it 'returns failure result' do
        service = described_class.new(
          user: user,
          brand: brand,
          provider: provider,
          token_value: '',
          mode: mode
        )

        result = service.call

        expect(result.success?).to be false
        expect(result.error).to eq('Token value is required')
        expect(result.data).to be_nil
      end

      it 'returns failure result for nil token value' do
        service = described_class.new(
          user: user,
          brand: brand,
          provider: provider,
          token_value: nil,
          mode: mode
        )

        result = service.call

        expect(result.success?).to be false
        expect(result.error).to eq('Token value is required')
        expect(result.data).to be_nil
      end
    end

    context 'when token save fails' do
      it 'returns failure result with validation errors' do
        service = described_class.new(
          user: user,
          brand: brand,
          provider: '', # Invalid provider
          token_value: token_value,
          mode: mode
        )

        result = service.call

        expect(result.success?).to be false
        expect(result.error).to include('Failed to save API token')
        expect(result.data).to be_nil
      end
    end

    context 'when an exception occurs' do
      it 'returns failure result with error message' do
        service = described_class.new(
          user: user,
          brand: brand,
          provider: provider,
          token_value: token_value,
          mode: mode
        )

        allow(service).to receive(:find_or_initialize_token).and_raise(StandardError, 'Database error')

        result = service.call

        expect(result.success?).to be false
        expect(result.error).to eq('Error updating API token: Database error')
        expect(result.data).to be_nil
      end
    end

    context 'with different providers' do
      [ 'openai', 'kling' ].each do |test_provider|
        it "handles #{test_provider} provider" do
          service = described_class.new(
            user: user,
            brand: brand,
            provider: test_provider,
            token_value: token_value,
            mode: mode
          )

          # Skip the token validation callback to avoid API calls
          ApiToken.skip_callback(:save, :before, :validate_token_with_provider)

          result = service.call

          ApiToken.set_callback(:save, :before, :validate_token_with_provider)

          expect(result.success?).to be true
          expect(result.data[:api_token].provider).to eq(test_provider)
        end
      end
    end

    context 'with different modes' do
      [ 'test', 'production' ].each do |test_mode|
        it "handles #{test_mode} mode" do
          service = described_class.new(
            user: user,
            brand: brand,
            provider: provider,
            token_value: token_value,
            mode: test_mode
          )

          # Skip the token validation callback to avoid API calls
          ApiToken.skip_callback(:save, :before, :validate_token_with_provider)

          result = service.call

          ApiToken.set_callback(:save, :before, :validate_token_with_provider)

          expect(result.success?).to be true
          expect(result.data[:api_token].mode).to eq(test_mode)
        end
      end
    end
  end

  describe 'private methods' do
    let(:service) do
      described_class.new(
        user: user,
        brand: brand,
        provider: provider,
        token_value: token_value,
        mode: mode
      )
    end

    describe '#find_or_initialize_token' do
      it 'finds existing token' do
        # Skip the token validation callback to avoid API calls
        ApiToken.skip_callback(:save, :before, :validate_token_with_provider)
        existing_token = create(:api_token, :heygen, user: user, brand: brand, mode: mode)
        ApiToken.set_callback(:save, :before, :validate_token_with_provider)

        found_token = service.send(:find_or_initialize_token)

        expect(found_token.id).to eq(existing_token.id)
        expect(found_token.persisted?).to be true
      end

      it 'initializes new token' do
        token = service.send(:find_or_initialize_token)

        expect(token.persisted?).to be false
        expect(token.provider).to eq(provider)
        expect(token.mode).to eq(mode)
        expect(token.user).to eq(user)
      end
    end

    describe '#update_token_attributes' do
      it 'sets encrypted_token' do
        token = ApiToken.new
        service.send(:update_token_attributes, token)

        expect(token.encrypted_token).to eq(token_value)
      end

      it 'sets group_url for heygen provider' do
        group_url = 'https://app.heygen.com/group/test123'
        service = described_class.new(
          user: user,
          brand: brand,
          provider: 'heygen',
          token_value: token_value,
          mode: mode,
          group_url: group_url
        )

        token = ApiToken.new
        service.send(:update_token_attributes, token)

        expect(token.group_url).to eq(group_url)
      end

      it 'does not set group_url for non-heygen provider' do
        service = described_class.new(
          user: user,
          brand: brand,
          provider: 'openai',
          token_value: token_value,
          mode: mode,
          group_url: 'https://example.com'
        )

        token = ApiToken.new
        service.send(:update_token_attributes, token)

        expect(token.group_url).to be_nil
      end
    end

    describe 'result methods' do
      describe '#success_result' do
        it 'returns success result structure' do
          api_token = build(:api_token)
          result = service.send(:success_result, api_token: api_token)

          expect(result.success?).to be true
          expect(result.data[:api_token]).to eq(api_token)
          expect(result.error).to be_nil
        end
      end

      describe '#failure_result' do
        it 'returns failure result structure' do
          error_message = 'Test error'
          result = service.send(:failure_result, error_message)

          expect(result.success?).to be false
          expect(result.data).to be_nil
          expect(result.error).to eq(error_message)
        end
      end
    end
  end
end
