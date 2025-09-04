require 'rails_helper'

RSpec.describe Heygen::ValidateKeyService, type: :service do
  let(:token) { 'sk-test_token_123' }
  let(:mode) { 'test' }

  subject { described_class.new(token: token, mode: mode) }

  describe '#call' do
    context 'when token is valid', :vcr do
      it 'returns valid: true' do
        result = subject.call

        expect(result).to have_key(:valid)
        expect(result[:error]).to be_nil if result[:valid]
      end
    end

    context 'when token is invalid', :vcr do
      let(:token) { 'invalid_token' }

      it 'returns valid: false with error message' do
        result = subject.call

        expect(result[:valid]).to be false
        expect(result[:error]).to be_present
        expect(result[:error]).to include('Invalid Heygen API token')
      end
    end

    context 'when no token provided' do
      let(:token) { nil }

      it 'returns valid: false with error message' do
        result = subject.call

        expect(result[:valid]).to be false
        expect(result[:error]).to eq('No token provided')
      end
    end

    context 'when API returns 404', :vcr do
      let(:token) { 'nonexistent_token' }

      it 'returns valid: false with error message' do
        result = subject.call

        expect(result[:valid]).to be false
        expect(result[:error]).to be_present
      end
    end

    context 'when API call raises an exception' do
      before do
        allow_any_instance_of(Http::BaseClient).to receive(:get).and_raise(StandardError, 'Connection failed')
      end

      it 'returns valid: false with error message' do
        result = subject.call

        expect(result[:valid]).to be false
        expect(result[:error]).to eq('Token validation failed: Connection failed')
      end
    end
  end
end