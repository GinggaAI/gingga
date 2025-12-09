require 'rails_helper'

RSpec.describe GinggaOpenAI::ValidateAndUpdateService do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }
  let(:mode) { "production" }
  let(:service) { described_class.new(user: user, brand: brand, mode: mode) }

  # Stub API token validation that happens in before_save callback
  before do
    allow_any_instance_of(ApiTokenValidatorService).to receive(:call).and_return({ valid: true })
    # Skip the before_save callback that validates tokens to avoid interference with test expectations
    allow_any_instance_of(ApiToken).to receive(:validate_token_with_provider).and_return(true)
  end

  describe '#call' do
    context 'when token exists' do
      let!(:api_token) do
        token = create(:api_token, :openai, user: user, brand: brand, mode: mode)
        # Use update_columns to bypass callbacks and set is_valid to false for testing
        token.update_columns(is_valid: false)
        token
      end

      context 'when validation succeeds' do
        before do
          allow_any_instance_of(GinggaOpenAI::ValidateKeyService).to receive(:call).and_return({ valid: true })
        end

        it 'returns success result' do
          result = service.call

          expect(result.success?).to be true
          expect(result.data).to eq({ message: "OpenAI API key validated successfully" })
          expect(result.error).to be_nil
        end

        it 'updates token is_valid to true' do
          expect {
            service.call
          }.to change { api_token.reload.is_valid }.from(false).to(true)
        end
      end

      context 'when validation fails' do
        before do
          allow_any_instance_of(GinggaOpenAI::ValidateKeyService).to receive(:call).and_return({ valid: false, error: 'Invalid API key' })
        end

        it 'returns failure result with error message' do
          # Ensure token starts as valid for this test
          api_token.update_columns(is_valid: true)
          api_token.reload

          result = service.call

          expect(result.success?).to be false
          expect(result.data).to be_nil
          expect(result.error).to eq('Invalid API key')
        end

        it 'updates token is_valid to false' do
          # Ensure token starts as valid for this test
          api_token.update_columns(is_valid: true)
          api_token.reload

          expect {
            service.call
          }.to change { api_token.reload.is_valid }.from(true).to(false)
        end
      end

      context 'when validation returns valid false without error message' do
        before do
          allow_any_instance_of(GinggaOpenAI::ValidateKeyService).to receive(:call).and_return({ valid: false })
        end

        it 'returns generic failure message' do
          # Ensure token starts as valid for this test
          api_token.update_columns(is_valid: true)
          api_token.reload

          result = service.call

          expect(result.success?).to be false
          expect(result.error).to eq('Token validation failed')
        end

        it 'updates token is_valid to false' do
          # Ensure token starts as valid for this test
          api_token.update_columns(is_valid: true)
          api_token.reload

          expect {
            service.call
          }.to change { api_token.reload.is_valid }.from(true).to(false)
        end
      end
    end

    context 'when no token exists' do
      it 'returns failure result' do
        result = service.call

        expect(result.success?).to be false
        expect(result.data).to be_nil
        expect(result.error).to eq('No API token found. Please save an OpenAI API key first.')
      end
    end

    context 'when StandardError is raised' do
      let!(:api_token) do
        create(:api_token, :openai, user: user, brand: brand, mode: mode)
      end

      before do
        allow_any_instance_of(GinggaOpenAI::ValidateKeyService).to receive(:call).and_raise(StandardError, 'Network timeout')
      end

      it 'catches the error and returns failure result' do
        result = service.call

        expect(result.success?).to be false
        expect(result.error).to eq('Validation error: Network timeout')
      end
    end

    context 'with different modes' do
      let!(:test_token) do
        create(:api_token, :openai, :test_mode, user: user, brand: brand)
      end
      let!(:production_token) do
        create(:api_token, :openai, :production_mode, user: user, brand: brand)
      end

      context 'when mode is test' do
        let(:mode) { 'test' }

        before do
          allow_any_instance_of(GinggaOpenAI::ValidateKeyService).to receive(:call).and_return({ valid: true })
        end

        it 'finds and validates test mode token' do
          result = service.call

          expect(result.success?).to be true
        end
      end

      context 'when mode is production' do
        let(:mode) { 'production' }

        before do
          allow_any_instance_of(GinggaOpenAI::ValidateKeyService).to receive(:call).and_return({ valid: true })
        end

        it 'finds and validates production mode token' do
          result = service.call

          expect(result.success?).to be true
        end
      end
    end

    context 'Result struct' do
      let!(:api_token) do
        create(:api_token, :openai, user: user, brand: brand, mode: mode)
      end

      before do
        allow_any_instance_of(GinggaOpenAI::ValidateKeyService).to receive(:call).and_return({ valid: true })
      end

      it 'returns a Result struct with keyword arguments' do
        result = service.call

        expect(result).to be_a(GinggaOpenAI::ValidateAndUpdateService::Result)
        expect(result).to respond_to(:success?)
        expect(result).to respond_to(:data)
        expect(result).to respond_to(:error)
      end
    end

    context 'integration with ValidateKeyService' do
      let!(:api_token) do
        create(:api_token, :openai, user: user, brand: brand, mode: mode, encrypted_token: 'test-token-123')
      end

      it 'passes correct parameters to ValidateKeyService' do
        expect(GinggaOpenAI::ValidateKeyService).to receive(:new).with(
          token: 'test-token-123',
          mode: mode
        ).and_call_original

        allow_any_instance_of(GinggaOpenAI::ValidateKeyService).to receive(:call).and_return({ valid: true })

        service.call
      end
    end

    context 'when brand has multiple tokens' do
      let!(:openai_token) do
        create(:api_token, :openai, user: user, brand: brand, mode: mode)
      end
      let!(:heygen_token) do
        create(:api_token, :heygen, user: user, brand: brand, mode: mode)
      end

      before do
        allow_any_instance_of(GinggaOpenAI::ValidateKeyService).to receive(:call).and_return({ valid: true })
      end

      it 'only validates the OpenAI token' do
        result = service.call

        expect(result.success?).to be true
        expect(openai_token.reload.is_valid).to be true
        # heygen_token should remain unchanged
        expect(heygen_token.reload.is_valid).to be true
      end
    end
  end

  describe 'private methods' do
    let!(:api_token) do
      create(:api_token, :openai, user: user, brand: brand, mode: mode)
    end

    describe '#find_token' do
      it 'finds token by provider and mode' do
        token = service.send(:find_token)

        expect(token).to eq(api_token)
      end
    end

    describe '#validate_token' do
      before do
        allow_any_instance_of(GinggaOpenAI::ValidateKeyService).to receive(:call).and_return({ valid: true })
      end

      it 'calls ValidateKeyService with token and mode' do
        result = service.send(:validate_token, api_token)

        expect(result).to eq({ valid: true })
      end
    end

    describe '#success_result' do
      it 'returns a success Result struct' do
        result = service.send(:success_result)

        expect(result.success?).to be true
        expect(result.data).to eq({ message: "OpenAI API key validated successfully" })
        expect(result.error).to be_nil
      end
    end

    describe '#failure_result' do
      it 'returns a failure Result struct with error message' do
        result = service.send(:failure_result, "Custom error message")

        expect(result.success?).to be false
        expect(result.data).to be_nil
        expect(result.error).to eq("Custom error message")
      end
    end
  end
end
