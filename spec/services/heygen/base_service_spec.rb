require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Heygen::BaseService, type: :service do
  let(:user) { create(:user) }

  before do
    # Stub Heygen validation endpoint called during token creation
    stub_request(:get, "https://api.heygen.com/v2/avatars")
      .to_return(status: 200, body: '{"data": []}')
  end

  let!(:api_token) do
    token = build(:api_token, user: user, provider: 'heygen', is_valid: true)
    token.save(validate: false)
    token
  end

  # Create a concrete test class since BaseService is abstract
  let(:test_service_class) do
    Class.new(Heygen::BaseService) do
      def call
        success_result("test data")
      end

      def test_get(path, query: {})
        get(path, query: query)
      end

      def test_post(path, body: {})
        post(path, body: body)
      end

      def test_parse_json(response)
        parse_json(response)
      end
    end
  end

  subject { test_service_class.new(user) }

  describe '#initialize' do
    context 'when user has valid API token' do
      it 'initializes successfully' do
        expect { subject }.not_to raise_error
        expect(subject.send(:api_token_present?)).to be true
      end
    end

    context 'when user has no API token' do
      let(:user_without_token) { create(:user) }
      subject { test_service_class.new(user_without_token) }

      it 'initializes but api_token_present? returns false' do
        expect { subject }.not_to raise_error
        expect(subject.send(:api_token_present?)).to be false
      end
    end
  end

  describe '#api_token_present?' do
    it 'returns true when token exists' do
      expect(subject.send(:api_token_present?)).to be true
    end

    context 'when no token' do
      let(:user_without_token) { create(:user) }
      subject { test_service_class.new(user_without_token) }

      it 'returns false when token does not exist' do
        expect(subject.send(:api_token_present?)).to be false
      end
    end
  end

  describe '#headers' do
    it 'returns correct headers with API token' do
      headers = subject.send(:headers)

      expect(headers).to eq({
        "X-API-KEY" => api_token.encrypted_token,
        "Content-Type" => "application/json"
      })
    end
  end

  describe '#get' do
    context 'when request is successful' do
      before do
        stub_request(:get, "https://api.heygen.com/test/path")
          .with(
            query: { param: 'value' },
            headers: {
              'X-API-KEY' => api_token.encrypted_token,
              'Content-Type' => 'application/json'
            }
          )
          .to_return(status: 200, body: '{"success": true}')
      end

      it 'makes GET request with correct parameters' do
        response = subject.test_get('/test/path', query: { param: 'value' })

        expect(response.success?).to be true
        expect(response.body).to eq('{"success": true}')
      end
    end

    context 'when request raises StandardError' do
      before do
        allow(Heygen::BaseService).to receive(:get).and_raise(StandardError, 'Network error')
      end

      it 'raises StandardError with original message' do
        expect {
          subject.test_get('/test/path')
        }.to raise_error(StandardError, 'Network error')
      end
    end

    context 'when request raises timeout-like error' do
      before do
        # Create a mock timeout error
        timeout_error = StandardError.new('timeout occurred')
        allow(subject).to receive(:timeout_error?).with(timeout_error).and_return(true)
        allow(Heygen::BaseService).to receive(:get).and_raise(timeout_error)
      end

      it 'raises StandardError with timeout message' do
        expect {
          subject.test_get('/test/path')
        }.to raise_error(StandardError, 'Request timeout: timeout occurred')
      end
    end
  end

  describe '#post' do
    context 'when request is successful' do
      before do
        stub_request(:post, "https://api.heygen.com/test/path")
          .with(
            body: '{"key":"value"}',
            headers: {
              'X-API-KEY' => api_token.encrypted_token,
              'Content-Type' => 'application/json'
            }
          )
          .to_return(status: 200, body: '{"success": true}')
      end

      it 'makes POST request with correct parameters' do
        response = subject.test_post('/test/path', body: { key: 'value' })

        expect(response.success?).to be true
        expect(response.body).to eq('{"success": true}')
      end
    end

    context 'when body is already a string' do
      before do
        stub_request(:post, "https://api.heygen.com/test/path")
          .with(
            body: '{"key":"value"}',
            headers: {
              'X-API-KEY' => api_token.encrypted_token,
              'Content-Type' => 'application/json'
            }
          )
          .to_return(status: 200, body: '{"success": true}')
      end

      it 'uses the string body as-is' do
        response = subject.test_post('/test/path', body: '{"key":"value"}')

        expect(response.success?).to be true
      end
    end

    context 'when request raises StandardError' do
      before do
        allow(Heygen::BaseService).to receive(:post).and_raise(StandardError, 'Network error')
      end

      it 'raises StandardError with original message' do
        expect {
          subject.test_post('/test/path', body: {})
        }.to raise_error(StandardError, 'Network error')
      end
    end
  end

  describe '#parse_json' do
    context 'with valid JSON response' do
      let(:response) { double(body: '{"key": "value"}') }

      it 'parses JSON correctly' do
        result = subject.test_parse_json(response)
        expect(result).to eq({ "key" => "value" })
      end
    end

    context 'with invalid JSON response' do
      let(:response) { double(body: 'invalid json') }

      it 'returns empty hash and logs warning' do
        expect(Rails.logger).to receive(:warn).with(/JSON parse error/)
        result = subject.test_parse_json(response)
        expect(result).to eq({ error: "Invalid JSON response" })
      end
    end

    context 'with nil body' do
      let(:response) { double(body: nil) }

      it 'returns empty hash' do
        result = subject.test_parse_json(response)
        expect(result).to eq({})
      end
    end
  end

  describe '#success_result' do
    it 'returns success format' do
      result = subject.send(:success_result, { test: 'data' })
      expect(result).to eq({ success: true, data: { test: 'data' } })
    end
  end

  describe '#failure_result' do
    it 'returns failure format' do
      result = subject.send(:failure_result, 'Error message')
      expect(result).to eq({ success: false, error: 'Error message' })
    end
  end

  describe '#cache_key_for' do
    it 'generates correct cache key' do
      cache_key = subject.send(:cache_key_for, 'avatars')
      expected_key = "heygen_avatars_#{user.id}_#{api_token.mode}"
      expect(cache_key).to eq(expected_key)
    end
  end

  describe 'timeout_error? (private method)' do
    it 'returns false for regular StandardError' do
      error = StandardError.new('regular error')
      result = subject.send(:timeout_error?, error)
      expect(result).to be false
    end

    context 'when Net::TimeoutError is defined' do
      before do
        stub_const('Net::TimeoutError', Class.new(StandardError))
        stub_const('Net::ReadTimeout', Class.new(StandardError))
      end

      it 'returns true for Net::TimeoutError' do
        error = Net::TimeoutError.new('timeout')
        result = subject.send(:timeout_error?, error)
        expect(result).to be true
      end

      it 'returns true for Net::ReadTimeout' do
        error = Net::ReadTimeout.new('read timeout')
        result = subject.send(:timeout_error?, error)
        expect(result).to be true
      end
    end
  end
end
