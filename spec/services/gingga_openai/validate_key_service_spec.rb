require 'rails_helper'
require 'webmock/rspec'
require Rails.root.join('app/services/gingga_openai/validate_key_service')

RSpec.describe GinggaOpenAI::ValidateKeyService do
  describe '#call' do
    let(:service) { described_class.new(token: token, mode: mode) }
    let(:token) { 'sk-test123' }
    let(:mode) { 'production' }
    let(:api_url) { 'https://api.openai.com/v1/models' }

    before do
      WebMock.disable_net_connect!
    end

    after do
      WebMock.allow_net_connect!
    end

    context 'with valid token' do
      it 'returns valid true for 200 response' do
        stub_request(:get, api_url)
          .with(headers: { 'Authorization' => "Bearer #{token}" })
          .to_return(status: 200, body: '{"data": []}')

        result = service.call
        expect(result).to eq({ valid: true })
      end
    end

    context 'with invalid token' do
      it 'returns valid false for 401 response' do
        stub_request(:get, api_url)
          .with(headers: { 'Authorization' => "Bearer #{token}" })
          .to_return(status: 401, body: '{"error": "Invalid API key"}')

        result = service.call
        expect(result).to eq({ valid: false, error: 'Invalid API key' })
      end
    end

    context 'with API error' do
      it 'returns valid false for non-200/401 response' do
        stub_request(:get, api_url)
          .with(headers: { 'Authorization' => "Bearer #{token}" })
          .to_return(status: 500, body: '{"error": "Server error"}')

        result = service.call
        expect(result).to eq({ valid: false, error: 'API validation failed with status 500' })
      end
    end

    context 'with network error' do
      it 'returns valid false for network failure' do
        stub_request(:get, api_url)
          .with(headers: { 'Authorization' => "Bearer #{token}" })
          .to_raise(StandardError, 'Connection failed')

        result = service.call
        expect(result).to have_key(:valid)
        expect(result).to have_key(:error)
        expect(result[:valid]).to be false
        expect(result[:error]).to match(/Network error:.*/)  # Allow for WebMock variations
      end
    end

    context 'with invalid mode' do
      let(:mode) { 'invalid' }

      it 'returns valid false for invalid mode' do
        result = service.call
        expect(result).to eq({ valid: false, error: 'Invalid mode' })
      end
    end

    context 'with test mode' do
      let(:mode) { 'test' }

      it 'uses correct API URL for test mode' do
        stub_request(:get, api_url)
          .with(headers: { 'Authorization' => "Bearer #{token}" })
          .to_return(status: 200, body: '{"data": []}')

        result = service.call
        expect(result).to eq({ valid: true })
      end
    end
  end
end
