require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Heygen::ValidateKeyService, type: :service do
  let(:token) { 'sk-test_token_123' }
  let(:mode) { 'test' }
  
  subject { described_class.new(token: token, mode: mode) }

  describe '#call' do
    context 'when token is valid' do
      before do
        stub_request(:get, "https://api.heygen.com/v2/avatars")
          .with(headers: {
            'X-API-KEY' => token,
            'Content-Type' => 'application/json'
          })
          .to_return(status: 200, body: '{"data": {"avatars": []}}')
      end

      it 'returns valid: true' do
        result = subject.call
        
        expect(result[:valid]).to be true
        expect(result[:error]).to be_nil
      end
    end

    context 'when token is invalid' do
      before do
        stub_request(:get, "https://api.heygen.com/v2/avatars")
          .with(headers: {
            'X-API-KEY' => token,
            'Content-Type' => 'application/json'
          })
          .to_return(status: 401, body: '{"error": "Unauthorized"}')
      end

      it 'returns valid: false with error message' do
        result = subject.call
        
        expect(result[:valid]).to be false
        expect(result[:error]).to include('Invalid Heygen API token')
        expect(result[:error]).to include('401')
      end
    end

    context 'when API call raises an exception' do
      before do
        stub_request(:get, "https://api.heygen.com/v2/avatars")
          .with(headers: {
            'X-API-KEY' => token,
            'Content-Type' => 'application/json'
          })
          .to_raise(StandardError, 'Network error')
      end

      it 'returns valid: false with error message' do
        result = subject.call
        
        expect(result[:valid]).to be false
        expect(result[:error]).to include('Token validation failed:')
      end
    end

    context 'when API returns 404' do
      before do
        stub_request(:get, "https://api.heygen.com/v2/avatars")
          .with(headers: {
            'X-API-KEY' => token,
            'Content-Type' => 'application/json'
          })
          .to_return(status: 404, body: '{"error": "Not found"}')
      end

      it 'returns valid: false with error message' do
        result = subject.call
        
        expect(result[:valid]).to be false
        expect(result[:error]).to include('Invalid Heygen API token')
        expect(result[:error]).to include('404')
      end
    end
  end
end