require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Kling::ValidateKeyService, type: :service do
  let(:token) { 'sk-kling_test_token_123' }
  let(:mode) { 'test' }

  subject { described_class.new(token: token, mode: mode) }

  describe '#initialize' do
    it 'sets the token and mode' do
      service = described_class.new(token: token, mode: mode)
      expect(service.send(:token)).to eq(token)
      expect(service.send(:mode)).to eq(mode)
    end
  end

  describe '#call' do
    context 'when mode is invalid' do
      let(:mode) { 'invalid_mode' }

      it 'returns valid: false with error message' do
        result = subject.call

        expect(result[:valid]).to be false
        expect(result[:error]).to eq('Invalid mode')
      end
    end

    context 'when mode is valid' do
      context 'with test mode' do
        let(:mode) { 'test' }

        context 'when API key is valid (200 response)' do
          before do
            stub_request(:get, "https://api.kling.ai/v1/models")
              .with(headers: {
                'Authorization' => "Bearer #{token}",
                'Content-Type' => 'application/json'
              })
              .to_return(status: 200, body: '{"data": {"models": []}}')
          end

          it 'returns valid: true' do
            result = subject.call

            expect(result[:valid]).to be true
            expect(result[:error]).to be_nil
          end
        end

        context 'when API key is invalid (401 response)' do
          before do
            stub_request(:get, "https://api.kling.ai/v1/models")
              .with(headers: {
                'Authorization' => "Bearer #{token}",
                'Content-Type' => 'application/json'
              })
              .to_return(status: 401, body: '{"error": {"message": "Invalid API key"}}')
          end

          it 'returns valid: false with error message' do
            result = subject.call

            expect(result[:valid]).to be false
            expect(result[:error]).to eq('Invalid API key')
          end
        end

        context 'when API key is forbidden (403 response)' do
          before do
            stub_request(:get, "https://api.kling.ai/v1/models")
              .with(headers: {
                'Authorization' => "Bearer #{token}",
                'Content-Type' => 'application/json'
              })
              .to_return(status: 403, body: '{"error": {"message": "Forbidden"}}')
          end

          it 'returns valid: false with error message' do
            result = subject.call

            expect(result[:valid]).to be false
            expect(result[:error]).to eq('Invalid API key')
          end
        end

        context 'when API returns other HTTP error' do
          before do
            stub_request(:get, "https://api.kling.ai/v1/models")
              .with(headers: {
                'Authorization' => "Bearer #{token}",
                'Content-Type' => 'application/json'
              })
              .to_return(status: 500, body: '{"error": "Internal server error"}')
          end

          it 'returns valid: false with status error message' do
            result = subject.call

            expect(result[:valid]).to be false
            expect(result[:error]).to eq('API validation failed with status 500')
          end
        end

        context 'when network error occurs' do
          before do
            stub_request(:get, "https://api.kling.ai/v1/models")
              .with(headers: {
                'Authorization' => "Bearer #{token}",
                'Content-Type' => 'application/json'
              })
              .to_raise(Timeout::Error.new('Request timeout'))
          end

          it 'returns valid: false with network error message' do
            result = subject.call

            expect(result[:valid]).to be false
            expect(result[:error]).to eq('Network error: Request timeout')
          end
        end

        context 'when connection failed' do
          before do
            stub_request(:get, "https://api.kling.ai/v1/models")
              .with(headers: {
                'Authorization' => "Bearer #{token}",
                'Content-Type' => 'application/json'
              })
              .to_raise(Errno::ECONNREFUSED.new('Connection refused'))
          end

          it 'returns valid: false with network error message' do
            result = subject.call

            expect(result[:valid]).to be false
            expect(result[:error]).to match(/Network error: Connection refused/)
          end
        end
      end

      context 'with production mode' do
        let(:mode) { 'production' }

        context 'when API key is valid' do
          before do
            stub_request(:get, "https://api.kling.ai/v1/models")
              .with(headers: {
                'Authorization' => "Bearer #{token}",
                'Content-Type' => 'application/json'
              })
              .to_return(status: 200, body: '{"data": {"models": []}}')
          end

          it 'returns valid: true' do
            result = subject.call

            expect(result[:valid]).to be true
            expect(result[:error]).to be_nil
          end
        end
      end
    end
  end

  describe '#make_request' do
    let(:service) { described_class.new(token: token, mode: mode) }

    it 'creates correct HTTP request' do
      stub_request(:get, "https://api.kling.ai/v1/models")
        .with(headers: {
          'Authorization' => "Bearer #{token}",
          'Content-Type' => 'application/json'
        })
        .to_return(status: 200)

      service.send(:make_request)

      expect(a_request(:get, "https://api.kling.ai/v1/models")
        .with(headers: {
          'Authorization' => "Bearer #{token}",
          'Content-Type' => 'application/json'
        })).to have_been_made
    end
  end

  describe 'API_URLS constant' do
    it 'has correct test URL' do
      expect(Kling::ValidateKeyService::API_URLS['test']).to eq('https://api.kling.ai/v1/models')
    end

    it 'has correct production URL' do
      expect(Kling::ValidateKeyService::API_URLS['production']).to eq('https://api.kling.ai/v1/models')
    end

    it 'is frozen' do
      expect(Kling::ValidateKeyService::API_URLS).to be_frozen
    end
  end
end
