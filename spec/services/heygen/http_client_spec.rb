require 'rails_helper'

RSpec.describe Heygen::HttpClient, type: :service do
  let(:user) { create(:user) }
  let(:encrypted_token) { "encrypted_heygen_token_123" }
  let(:api_token) { double('api_token', encrypted_token: encrypted_token) }

  before do
    allow(user).to receive(:active_token_for).with("heygen").and_return(api_token)
    # Mock environment variables
    allow(ENV).to receive(:fetch).with("HEYGEN_API_BASE", "https://api.heygen.com").and_return("https://api.heygen.com")
  end

  describe '#initialize' do
    context 'with valid user and token' do
      it 'initializes successfully with correct base configuration' do
        client = described_class.new(user: user)

        expect(client.instance_variable_get(:@user)).to eq(user)
        expect(client.instance_variable_get(:@api_token)).to eq(api_token)
      end

      it 'inherits from Http::BaseClient properly' do
        client = described_class.new(user: user)
        
        expect(client).to be_a(::Http::BaseClient)
        expect(client.instance_variable_get(:@user)).to eq(user)
        expect(client.instance_variable_get(:@api_token)).to eq(api_token)
      end

      it 'uses custom HEYGEN_API_BASE when provided' do
        custom_base_url = "https://custom.heygen.com"
        allow(ENV).to receive(:fetch).with("HEYGEN_API_BASE", "https://api.heygen.com").and_return(custom_base_url)

        client = described_class.new(user: user)
        
        expect(client).to be_a(::Http::BaseClient)
        expect(client.instance_variable_get(:@user)).to eq(user)
      end
    end

    context 'when user has no active token' do
      before do
        allow(user).to receive(:active_token_for).with("heygen").and_return(nil)
      end

      it 'raises ArgumentError' do
        expect { described_class.new(user: user) }.to raise_error(
          ArgumentError, "No valid Heygen API token found for user"
        )
      end
    end

    context 'when api_token exists but encrypted_token is nil' do
      let(:api_token_without_token) { double('api_token', encrypted_token: nil) }

      before do
        allow(user).to receive(:active_token_for).with("heygen").and_return(api_token_without_token)
      end

      it 'raises ArgumentError' do
        expect { described_class.new(user: user) }.to raise_error(
          ArgumentError, "No valid Heygen API token found for user"
        )
      end
    end

    context 'when api_token exists but encrypted_token is empty' do
      let(:api_token_with_empty_token) { double('api_token', encrypted_token: "") }

      before do
        allow(user).to receive(:active_token_for).with("heygen").and_return(api_token_with_empty_token)
      end

      it 'raises ArgumentError' do
        expect { described_class.new(user: user) }.to raise_error(
          ArgumentError, "No valid Heygen API token found for user"
        )
      end
    end
  end

  describe '#get_with_logging' do
    let(:client) { described_class.new(user: user) }
    let(:path) { "/v1/avatars" }
    let(:params) { { limit: 10 } }
    let(:headers) { { "Accept" => "application/json" } }
    let(:api_result) do
      {
        success: true,
        status: 200,
        data: { avatars: [] },
        response_time_ms: 150,
        error: nil
      }
    end

    before do
      allow(client).to receive(:get).and_return(api_result)
      allow(client).to receive(:log_api_call)
    end

    it 'calls the parent get method with correct parameters' do
      expect(client).to receive(:get).with(path, params: params, headers: headers)
      client.get_with_logging(path, params: params, headers: headers)
    end

    it 'logs the API call with correct parameters' do
      expect(client).to receive(:log_api_call).with(
        path,
        { query: params, headers: headers },
        api_result
      )
      client.get_with_logging(path, params: params, headers: headers)
    end

    it 'returns the result from the parent get method' do
      result = client.get_with_logging(path, params: params, headers: headers)
      expect(result).to eq(api_result)
    end

    context 'with default parameters' do
      it 'handles missing params and headers' do
        expect(client).to receive(:get).with(path, params: {}, headers: {})
        expect(client).to receive(:log_api_call).with(
          path,
          { query: {}, headers: {} },
          api_result
        )

        client.get_with_logging(path)
      end
    end

    context 'when API call fails' do
      let(:failed_result) do
        {
          success: false,
          status: 500,
          data: nil,
          response_time_ms: 300,
          error: { message: "Internal Server Error" }
        }
      end

      before do
        allow(client).to receive(:get).and_return(failed_result)
      end

      it 'still logs the failed call' do
        expect(client).to receive(:log_api_call).with(
          path,
          { query: params, headers: headers },
          failed_result
        )
        client.get_with_logging(path, params: params, headers: headers)
      end

      it 'returns the failed result' do
        result = client.get_with_logging(path, params: params, headers: headers)
        expect(result).to eq(failed_result)
      end
    end
  end

  describe '#post_with_logging' do
    let(:client) { described_class.new(user: user) }
    let(:path) { "/v1/videos" }
    let(:body) { { avatar_id: "123", script: "Hello world" } }
    let(:headers) { { "Content-Type" => "application/json" } }
    let(:api_result) do
      {
        success: true,
        status: 201,
        data: { video_id: "vid_123" },
        response_time_ms: 250,
        error: nil
      }
    end

    before do
      allow(client).to receive(:post).and_return(api_result)
      allow(client).to receive(:log_api_call)
      allow(client).to receive(:sanitize_body).and_return(body)
    end

    it 'calls the parent post method with correct parameters' do
      expect(client).to receive(:post).with(path, body: body, headers: headers)
      client.post_with_logging(path, body: body, headers: headers)
    end

    it 'logs the API call with sanitized body' do
      expect(client).to receive(:sanitize_body).with(body)
      expect(client).to receive(:log_api_call).with(
        path,
        { body: body, headers: headers },
        api_result
      )
      client.post_with_logging(path, body: body, headers: headers)
    end

    it 'returns the result from the parent post method' do
      result = client.post_with_logging(path, body: body, headers: headers)
      expect(result).to eq(api_result)
    end

    context 'with default parameters' do
      it 'handles missing body and headers' do
        expect(client).to receive(:post).with(path, body: {}, headers: {}).and_return(api_result)
        expect(client).to receive(:sanitize_body).with({}).and_return({})
        expect(client).to receive(:log_api_call).with(
          path,
          { body: {}, headers: {} },
          api_result
        )

        client.post_with_logging(path)
      end
    end

    context 'when POST call fails' do
      let(:failed_result) do
        {
          success: false,
          status: 422,
          data: nil,
          response_time_ms: 180,
          error: { message: "Validation failed" }
        }
      end

      before do
        allow(client).to receive(:post).and_return(failed_result)
      end

      it 'still logs the failed call' do
        expect(client).to receive(:log_api_call).with(
          path,
          { body: body, headers: headers },
          failed_result
        )
        client.post_with_logging(path, body: body, headers: headers)
      end

      it 'returns the failed result' do
        result = client.post_with_logging(path, body: body, headers: headers)
        expect(result).to eq(failed_result)
      end
    end
  end

  describe 'private methods' do
    let(:client) { described_class.new(user: user) }

    describe '#log_api_call' do
      let(:endpoint) { "/v1/test" }
      let(:request_data) { { query: { test: "value" } } }
      let(:result) do
        {
          success: true,
          status: 200,
          data: { result: "success" },
          response_time_ms: 100,
          error: nil
        }
      end

      before do
        # Mock ApiResponse class
        api_response_class = Class.new do
          def self.log_api_call(*)
            # Mock implementation
          end
        end
        stub_const('ApiResponse', api_response_class)
      end

      context 'when ApiResponse is defined and user exists' do
        it 'calls ApiResponse.log_api_call with correct parameters' do
          expect(ApiResponse).to receive(:log_api_call).with(
            provider: "heygen",
            endpoint: endpoint,
            user: user,
            request_data: request_data,
            response_data: result[:data],
            status_code: result[:status],
            response_time_ms: result[:response_time_ms],
            success: result[:success],
            error_message: nil
          )

          client.send(:log_api_call, endpoint, request_data, result)
        end

        context 'with error in result' do
          let(:result_with_error) do
            {
              success: false,
              status: 400,
              data: nil,
              response_time_ms: 200,
              error: { message: "Bad Request" }
            }
          end

          it 'extracts error message correctly' do
            expect(ApiResponse).to receive(:log_api_call).with(
              hash_including(
                success: false,
                error_message: "Bad Request"
              )
            )

            client.send(:log_api_call, endpoint, request_data, result_with_error)
          end
        end

        context 'when ApiResponse.log_api_call raises an exception' do
          before do
            allow(ApiResponse).to receive(:log_api_call).and_raise(StandardError, "Logging failed")
            allow(Rails.logger).to receive(:error)
          end

          it 'catches the exception and logs error' do
            expect(Rails.logger).to receive(:error).with("Failed to log API call: Logging failed")

            expect { client.send(:log_api_call, endpoint, request_data, result) }.not_to raise_error
          end
        end
      end

      context 'when ApiResponse is not defined' do
        before do
          hide_const('ApiResponse')
        end

        it 'does not attempt to log' do
          expect { client.send(:log_api_call, endpoint, request_data, result) }.not_to raise_error
        end
      end

      context 'when user is nil' do
        before do
          client.instance_variable_set(:@user, nil)
        end

        it 'does not attempt to log' do
          expect(ApiResponse).not_to receive(:log_api_call)
          client.send(:log_api_call, endpoint, request_data, result)
        end
      end
    end

    describe '#sanitize_headers' do
      it 'returns a copy of headers without API key' do
        headers = { "Accept" => "application/json", "X-Custom" => "value" }
        result = client.send(:sanitize_headers, headers)

        expect(result).to eq(headers)
        expect(result).not_to be(headers) # Should be a copy
      end

      it 'redacts X-API-KEY header' do
        headers = { "Accept" => "application/json", "X-API-KEY" => "secret_key" }
        result = client.send(:sanitize_headers, headers)

        expect(result["X-API-KEY"]).to eq("[REDACTED]")
        expect(result["Accept"]).to eq("application/json")
      end

      it 'handles empty headers' do
        result = client.send(:sanitize_headers, {})
        expect(result).to eq({})
      end

      it 'handles headers without X-API-KEY' do
        headers = { "Content-Type" => "application/json" }
        result = client.send(:sanitize_headers, headers)

        expect(result).to eq(headers)
      end

      it 'does not modify the original headers hash' do
        headers = { "X-API-KEY" => "secret_key", "Accept" => "application/json" }
        original_headers = headers.dup

        client.send(:sanitize_headers, headers)

        expect(headers).to eq(original_headers)
      end
    end

    describe '#sanitize_body' do
      it 'returns the body as-is' do
        body = { avatar_id: "123", script: "Hello" }
        result = client.send(:sanitize_body, body)

        expect(result).to eq(body)
        expect(result).to be(body) # Should be the same object
      end

      it 'handles empty body' do
        result = client.send(:sanitize_body, {})
        expect(result).to eq({})
      end

      it 'handles nil body' do
        result = client.send(:sanitize_body, nil)
        expect(result).to be_nil
      end

      it 'handles string body' do
        body = "test string"
        result = client.send(:sanitize_body, body)
        expect(result).to eq(body)
      end
    end
  end

  describe 'inheritance' do
    let(:client) { described_class.new(user: user) }

    it 'inherits from Http::BaseClient' do
      expect(described_class.superclass).to eq(::Http::BaseClient)
    end

    it 'responds to parent class methods' do
      expect(client).to respond_to(:get)
      expect(client).to respond_to(:post)
    end
  end

  describe 'method visibility' do
    let(:client) { described_class.new(user: user) }

    it 'makes log_api_call private' do
      expect(client.private_methods).to include(:log_api_call)
    end

    it 'makes sanitize_headers private' do
      expect(client.private_methods).to include(:sanitize_headers)
    end

    it 'makes sanitize_body private' do
      expect(client.private_methods).to include(:sanitize_body)
    end

    it 'makes public methods accessible' do
      expect(client).to respond_to(:get_with_logging)
      expect(client).to respond_to(:post_with_logging)
    end
  end

  describe 'error handling edge cases' do
    context 'when initializing with invalid user type' do
      it 'raises error when user does not respond to active_token_for' do
        invalid_user = "not_a_user_object"
        expect { described_class.new(user: invalid_user) }.to raise_error(NoMethodError)
      end
    end

    context 'when API calls return unexpected data structures' do
      let(:client) { described_class.new(user: user) }
      let(:malformed_result) { { unexpected: "structure" } }

      before do
        allow(client).to receive(:get).and_return(malformed_result)
        allow(client).to receive(:log_api_call)
      end

      it 'handles malformed results gracefully in get_with_logging' do
        expect { client.get_with_logging("/test") }.not_to raise_error
      end

      it 'passes through malformed results' do
        result = client.get_with_logging("/test")
        expect(result).to eq(malformed_result)
      end
    end
  end
end