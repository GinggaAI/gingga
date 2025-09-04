require 'rails_helper'

RSpec.describe Heygen::BaseService, type: :service do
  let(:user) { create(:user) }
  let!(:api_token) do
    token = build(:api_token, :heygen, user: user, is_valid: true)
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

      # Expose protected methods for testing
      def public_api_token_present?
        api_token_present?
      end
    end
  end

  subject { test_service_class.new(user) }

  describe '#initialize' do
    context 'when user has valid API token' do
      it 'initializes successfully with HTTP client' do
        expect { subject }.not_to raise_error
        expect(subject.public_api_token_present?).to be true
      end
    end

    context 'when user has no API token' do
      let(:user_without_token) { create(:user) }
      subject { test_service_class.new(user_without_token) }

      it 'initializes without HTTP client' do
        expect { subject }.not_to raise_error
        expect(subject.public_api_token_present?).to be false
      end
    end
  end

  describe 'success and failure methods' do
    it 'returns success result' do
      result = subject.call
      
      expect(result).to eq({ success: true, data: "test data" })
    end

    it 'returns failure result' do
      result = subject.send(:failure_result, "error message")
      
      expect(result).to eq({ success: false, error: "error message" })
    end
  end

  describe '#parse_json' do
    context 'with valid JSON hash' do
      it 'returns the hash as-is' do
        data = { "key" => "value" }
        result = subject.test_parse_json(data)
        
        expect(result).to eq(data)
      end
    end

    context 'with valid JSON string' do
      it 'parses JSON correctly' do
        json_string = '{"key": "value"}'
        result = subject.test_parse_json(json_string)
        
        expect(result).to eq({ "key" => "value" })
      end
    end

    context 'with invalid JSON string' do
      it 'returns error hash and logs warning' do
        expect(Rails.logger).to receive(:warn).with(/JSON parse error/)
        
        result = subject.test_parse_json('invalid json')
        
        expect(result).to eq({ error: "Invalid JSON response" })
      end
    end

    context 'with nil input' do
      it 'returns empty hash' do
        result = subject.test_parse_json(nil)
        
        expect(result).to eq({})
      end
    end
  end

  describe '#cache_key_for' do
    it 'generates correct cache key' do
      cache_key = subject.send(:cache_key_for, "avatars")
      
      expect(cache_key).to eq("heygen_avatars_#{user.id}_#{api_token.mode}")
    end
  end

  describe 'HTTP methods when no token present' do
    let(:user_without_token) { create(:user) }
    subject { test_service_class.new(user_without_token) }

    it '#test_get returns error response' do
      result = subject.test_get('/test')
      
      expect(result.success?).to be false
      expect(result.message).to include('No valid Heygen API token found')
    end

    it '#test_post returns error response' do
      result = subject.test_post('/test', body: { data: 'test' })
      
      expect(result.success?).to be false
      expect(result.message).to include('No valid Heygen API token found')
    end
  end
end