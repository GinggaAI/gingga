require 'rails_helper'

RSpec.describe ApiTokenValidatorService do
  describe '#call' do
    let(:service) { described_class.new(provider: provider, token: token, mode: mode) }
    let(:token) { 'test-token' }
    let(:mode) { 'production' }

    context 'with openai provider' do
      let(:provider) { 'openai' }
      let(:validator_instance) { instance_double(Openai::ValidateKeyService) }

      before do
        allow(Openai::ValidateKeyService).to receive(:new)
          .with(token: token, mode: mode)
          .and_return(validator_instance)
      end

      it 'dispatches to Openai::ValidateKeyService' do
        expect(validator_instance).to receive(:call).and_return({ valid: true })

        result = service.call
        expect(result).to eq({ valid: true })
      end

      it 'returns validation result' do
        allow(validator_instance).to receive(:call).and_return({ valid: false, error: 'Invalid token' })

        result = service.call
        expect(result).to eq({ valid: false, error: 'Invalid token' })
      end
    end

    context 'with heygen provider' do
      let(:provider) { 'heygen' }
      let(:validator_instance) { instance_double(Heygen::ValidateKeyService) }

      before do
        allow(Heygen::ValidateKeyService).to receive(:new)
          .with(token: token, mode: mode)
          .and_return(validator_instance)
      end

      it 'dispatches to Heygen::ValidateKeyService' do
        expect(validator_instance).to receive(:call).and_return({ valid: true })

        result = service.call
        expect(result).to eq({ valid: true })
      end

      it 'propagates error from underlying validator' do
        allow(validator_instance).to receive(:call).and_return({ valid: false, error: 'API key invalid' })

        result = service.call
        expect(result).to eq({ valid: false, error: 'API key invalid' })
      end
    end

    context 'with unsupported provider' do
      let(:provider) { 'unsupported' }

      it 'returns error for unsupported provider' do
        result = service.call
        expect(result).to eq({ valid: false, error: 'Unsupported provider: unsupported' })
      end
    end

    context 'when validator service raises error' do
      let(:provider) { 'openai' }

      before do
        allow(Openai::ValidateKeyService).to receive(:new).and_raise(StandardError, 'Network error')
      end

      it 'returns error message' do
        result = service.call
        expect(result).to eq({ valid: false, error: 'Validation failed: Network error' })
      end
    end
  end
end
