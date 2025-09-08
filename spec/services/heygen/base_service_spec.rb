require 'rails_helper'

RSpec.describe Heygen::BaseService, type: :service do
  let(:user) { create(:user) }
  let!(:api_token) do
    # Skip the before_save callback to avoid API calls in tests
    ApiToken.skip_callback(:save, :before, :validate_token_with_provider)
    token = create(:api_token, :heygen, user: user, is_valid: true)
    ApiToken.set_callback(:save, :before, :validate_token_with_provider)
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

  describe 'HTTP methods with valid token' do
    let(:mock_http_client) { double('http_client') }

    before do
      allow(Heygen::HttpClient).to receive(:new).with(user: user).and_return(mock_http_client)
    end

    describe '#get' do
      it 'delegates to http client get_with_logging' do
        successful_result = {
          success: true,
          status: 200,
          data: { test: 'data' },
          error: nil
        }

        expect(mock_http_client).to receive(:get_with_logging).with('/test', params: { limit: 10 }).and_return(successful_result)

        result = subject.test_get('/test', query: { limit: 10 })

        expect(result.success?).to be true
        expect(result.code).to eq(200)
        expect(result.body).to eq({ test: 'data' })
      end

      it 'handles failed API response' do
        failed_result = {
          success: false,
          status: 404,
          data: nil,
          error: { code: 404, message: 'Not Found', raw: { error: 'Resource not found' } }
        }

        expect(mock_http_client).to receive(:get_with_logging).with('/test', params: {}).and_return(failed_result)

        result = subject.test_get('/test')

        expect(result.success?).to be false
        expect(result.code).to eq(404)
        expect(result.message).to eq('Not Found')
        expect(result.body).to eq({ error: 'Resource not found' })
      end

      it 'handles exceptions during HTTP call' do
        expect(mock_http_client).to receive(:get_with_logging).and_raise(StandardError, 'Connection failed')

        result = subject.test_get('/test')

        expect(result.success?).to be false
        expect(result.message).to eq('HTTP request failed: Connection failed')
      end

      it 'handles ArgumentError exceptions specifically' do
        expect(mock_http_client).to receive(:get_with_logging).and_raise(ArgumentError, 'Invalid argument')

        result = subject.test_get('/test')

        expect(result.success?).to be false
        expect(result.message).to eq('Invalid argument')
      end
    end

    describe '#post' do
      it 'delegates to http client post_with_logging' do
        successful_result = {
          success: true,
          status: 201,
          data: { id: '123' },
          error: nil
        }

        expect(mock_http_client).to receive(:post_with_logging).with('/create', body: { name: 'test' }).and_return(successful_result)

        result = subject.test_post('/create', body: { name: 'test' })

        expect(result.success?).to be true
        expect(result.code).to eq(201)
        expect(result.body).to eq({ id: '123' })
      end

      it 'handles failed API response' do
        failed_result = {
          success: false,
          status: 422,
          data: nil,
          error: { code: 422, message: 'Validation failed', raw: { errors: [ 'Name required' ] } }
        }

        expect(mock_http_client).to receive(:post_with_logging).with('/create', body: {}).and_return(failed_result)

        result = subject.test_post('/create')

        expect(result.success?).to be false
        expect(result.code).to eq(422)
        expect(result.message).to eq('Validation failed')
        expect(result.body).to eq({ errors: [ 'Name required' ] })
      end

      it 'handles exceptions during HTTP call' do
        expect(mock_http_client).to receive(:post_with_logging).and_raise(StandardError, 'Network error')

        result = subject.test_post('/create')

        expect(result.success?).to be false
        expect(result.message).to eq('HTTP request failed: Network error')
      end
    end
  end

  describe 'initialization error handling' do
    context 'when HttpClient raises ArgumentError during initialization' do
      before do
        allow(Heygen::HttpClient).to receive(:new).with(user: user).and_raise(ArgumentError, 'Invalid token format')
      end

      subject { test_service_class.new(user) }

      it 'captures initialization error and sets http_client to nil' do
        expect(subject.public_api_token_present?).to be false
        expect(subject.send(:initialization_error)).to eq('Invalid token format')
      end

      it 'returns error response for GET requests' do
        result = subject.test_get('/test')

        expect(result.success?).to be false
        expect(result.message).to eq('Invalid token format')
      end

      it 'returns error response for POST requests' do
        result = subject.test_post('/test')

        expect(result.success?).to be false
        expect(result.message).to eq('Invalid token format')
      end
    end
  end

  describe 'private methods' do
    describe '#wrap_faraday_response' do
      it 'wraps successful response correctly' do
        faraday_result = {
          success: true,
          status: 200,
          data: { result: 'success' },
          error: nil
        }

        wrapped = subject.send(:wrap_faraday_response, faraday_result)

        expect(wrapped.success?).to be true
        expect(wrapped.code).to eq(200)
        expect(wrapped.status).to eq(200)
        expect(wrapped.body).to eq({ result: 'success' })
        expect(wrapped.message).to eq('OK')
      end

      it 'wraps failed response correctly' do
        faraday_result = {
          success: false,
          status: 400,
          data: nil,
          error: { code: 400, message: 'Bad Request', raw: { error: 'Invalid input' } }
        }

        wrapped = subject.send(:wrap_faraday_response, faraday_result)

        expect(wrapped.success?).to be false
        expect(wrapped.code).to eq(400)
        expect(wrapped.status).to eq(400)
        expect(wrapped.body).to eq({ error: 'Invalid input' })
        expect(wrapped.message).to eq('Bad Request')
      end

      it 'handles error without code' do
        faraday_result = {
          success: false,
          status: 500,
          data: nil,
          error: { message: 'Server Error' }
        }

        wrapped = subject.send(:wrap_faraday_response, faraday_result)

        expect(wrapped.code).to eq(0)
        expect(wrapped.body).to eq({ error: 'Server Error' })
      end

      it 'handles error without message' do
        faraday_result = {
          success: false,
          status: 500,
          data: nil,
          error: { code: 500 }
        }

        wrapped = subject.send(:wrap_faraday_response, faraday_result)

        expect(wrapped.message).to eq('Request failed')
        expect(wrapped.body).to eq({ error: nil })
      end
    end

    describe '#create_error_response' do
      it 'creates error response with correct structure' do
        response = subject.send(:create_error_response, 'Test error')

        expect(response.success?).to be false
        expect(response.code).to eq(0)
        expect(response.status).to eq(0)
        expect(response.message).to eq('Test error')
        expect(response.body).to eq({ error: 'Test error' })
      end
    end

    describe '#handle_http_error' do
      it 'handles ArgumentError specifically' do
        error = ArgumentError.new('Invalid argument')
        response = subject.send(:handle_http_error, error)

        expect(response.success?).to be false
        expect(response.message).to eq('Invalid argument')
      end

      it 'handles generic exceptions' do
        error = StandardError.new('Generic error')
        response = subject.send(:handle_http_error, error)

        expect(response.success?).to be false
        expect(response.message).to eq('HTTP request failed: Generic error')
      end

      it 'handles NoMethodError' do
        error = NoMethodError.new('Method not found')
        response = subject.send(:handle_http_error, error)

        expect(response.success?).to be false
        expect(response.message).to eq('HTTP request failed: Method not found')
      end
    end
  end

  describe '#parse_json' do
    context 'with array input' do
      it 'returns the array as-is' do
        data = [ { "key" => "value" } ]
        result = subject.test_parse_json(data)

        expect(result).to eq(data)
      end
    end

    context 'with numeric input' do
      it 'returns the number as-is' do
        result = subject.test_parse_json(123)
        expect(result).to eq(123)
      end
    end

    context 'with empty string' do
      it 'returns error hash for empty string JSON parsing' do
        expect(Rails.logger).to receive(:warn).with(/JSON parse error/)
        result = subject.test_parse_json("")
        expect(result).to eq({ error: "Invalid JSON response" })
      end
    end

    context 'with malformed JSON' do
      it 'handles missing closing brace' do
        expect(Rails.logger).to receive(:warn).with(/JSON parse error/)

        result = subject.test_parse_json('{"key": "value"')

        expect(result).to eq({ error: "Invalid JSON response" })
      end

      it 'handles invalid JSON characters' do
        expect(Rails.logger).to receive(:warn).with(/JSON parse error/)

        result = subject.test_parse_json('{"key": value}')

        expect(result).to eq({ error: "Invalid JSON response" })
      end
    end
  end

  describe 'initialization options handling' do
    it 'stores additional options' do
      service = test_service_class.new(user, timeout: 30, retries: 3)
      options = service.instance_variable_get(:@options)

      expect(options[:timeout]).to eq(30)
      expect(options[:retries]).to eq(3)
    end

    it 'handles empty options' do
      service = test_service_class.new(user)
      options = service.instance_variable_get(:@options)

      expect(options).to eq({})
    end
  end

  describe 'method visibility' do
    it 'makes protected methods accessible to subclasses' do
      expect(subject.protected_methods).to include(:api_token_present?)
      expect(subject.protected_methods).to include(:initialization_error)
      expect(subject.protected_methods).to include(:get)
      expect(subject.protected_methods).to include(:post)
      expect(subject.protected_methods).to include(:parse_json)
      expect(subject.protected_methods).to include(:success_result)
      expect(subject.protected_methods).to include(:failure_result)
      expect(subject.protected_methods).to include(:cache_key_for)
    end

    it 'makes private methods private' do
      expect(subject.private_methods).to include(:wrap_faraday_response)
      expect(subject.private_methods).to include(:create_error_response)
      expect(subject.private_methods).to include(:handle_http_error)
    end
  end

  describe 'edge cases and robustness' do
    context 'when user is nil' do
      it 'raises error during initialization' do
        expect { test_service_class.new(nil) }.to raise_error(NoMethodError)
      end
    end

    context 'with malformed API token' do
      let(:malformed_token) { double('token', encrypted_token: nil) }

      before do
        allow(user).to receive(:active_token_for).with("heygen").and_return(malformed_token)
      end

      it 'handles missing encrypted_token gracefully' do
        service = test_service_class.new(user)
        expect(service.public_api_token_present?).to be false
      end
    end

    context 'when cache_key_for is called without api_token' do
      let(:user_without_token) { create(:user) }
      subject { test_service_class.new(user_without_token) }

      it 'raises error when accessing api_token.mode' do
        expect { subject.send(:cache_key_for, "test") }.to raise_error(NoMethodError)
      end
    end
  end
end
