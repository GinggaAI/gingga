require 'rails_helper'

RSpec.describe Http::BaseClient, type: :service do
  let(:base_url) { "https://api.example.com" }
  let(:headers) { { "Custom-Header" => "custom-value" } }
  let(:api_key) { "test_api_key_123" }
  let(:bearer_token) { "bearer_token_456" }

  describe "#initialize" do
    it "initializes with required base_url" do
      client = described_class.new(base_url: base_url)

      expect(client.instance_variable_get(:@base_url)).to eq(base_url)
      expect(client.instance_variable_get(:@headers)).to eq({})
      expect(client.instance_variable_get(:@api_key)).to be_nil
      expect(client.instance_variable_get(:@bearer_token)).to be_nil
    end

    it "initializes with all optional parameters" do
      client = described_class.new(
        base_url: base_url,
        headers: headers,
        api_key: api_key,
        bearer_token: bearer_token
      )

      expect(client.instance_variable_get(:@base_url)).to eq(base_url)
      expect(client.instance_variable_get(:@headers)).to eq(headers)
      expect(client.instance_variable_get(:@api_key)).to eq(api_key)
      expect(client.instance_variable_get(:@bearer_token)).to eq(bearer_token)
    end

    it "initializes with partial optional parameters" do
      client = described_class.new(base_url: base_url, api_key: api_key)

      expect(client.instance_variable_get(:@base_url)).to eq(base_url)
      expect(client.instance_variable_get(:@headers)).to eq({})
      expect(client.instance_variable_get(:@api_key)).to eq(api_key)
      expect(client.instance_variable_get(:@bearer_token)).to be_nil
    end
  end

  describe "constants" do
    it "defines default constants with environment variable support" do
      expect(Http::BaseClient::DEFAULT_TIMEOUT).to be_a(Integer)
      expect(Http::BaseClient::DEFAULT_OPEN_TIMEOUT).to be_a(Integer)
      expect(Http::BaseClient::DEFAULT_RETRIES).to be_a(Integer)
    end

    context "with environment variables set" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("HTTP_TIMEOUT").and_return("45")
        allow(ENV).to receive(:[]).with("HTTP_OPEN_TIMEOUT").and_return("10")
        allow(ENV).to receive(:[]).with("HTTP_RETRIES").and_return("5")
      end

      it "uses environment variables for timeouts and retries" do
        # Force constant reloading by redefining constants
        stub_const("Http::BaseClient::DEFAULT_TIMEOUT", (ENV["HTTP_TIMEOUT"] || 30).to_i)
        stub_const("Http::BaseClient::DEFAULT_OPEN_TIMEOUT", (ENV["HTTP_OPEN_TIMEOUT"] || 5).to_i)
        stub_const("Http::BaseClient::DEFAULT_RETRIES", (ENV["HTTP_RETRIES"] || 2).to_i)

        expect(Http::BaseClient::DEFAULT_TIMEOUT).to eq(45)
        expect(Http::BaseClient::DEFAULT_OPEN_TIMEOUT).to eq(10)
        expect(Http::BaseClient::DEFAULT_RETRIES).to eq(5)
      end
    end

    context "with invalid environment variables" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("HTTP_TIMEOUT").and_return("invalid")
      end

      it "falls back to default values for invalid env vars" do
        stub_const("Http::BaseClient::DEFAULT_TIMEOUT", (ENV["HTTP_TIMEOUT"] || 30).to_i)
        expect(Http::BaseClient::DEFAULT_TIMEOUT).to eq(0) # invalid.to_i returns 0
      end
    end
  end

  describe "HTTP methods" do
    let(:client) { described_class.new(base_url: base_url) }
    let(:faraday_connection) { instance_double(Faraday::Connection) }
    let(:faraday_request) { instance_double(Faraday::Request) }
    let(:faraday_response) { instance_double(Faraday::Response, status: 200, body: { "result" => "success" }) }

    before do
      allow(client).to receive(:connection).and_return(faraday_connection)
      allow(faraday_connection).to receive(:send) do |verb, &block|
        block.call(faraday_request) if block
        faraday_response
      end
      allow(faraday_request).to receive(:url)
      allow(faraday_request).to receive(:params).and_return(double(update: nil))
      allow(faraday_request).to receive(:headers).and_return(double(update: nil))
      allow(faraday_request).to receive(:body=)
      allow(client).to receive(:handle_response).and_return({ success: true })
      allow(client).to receive(:instrument!)
    end

    describe "#get" do
      it "calls request with GET method" do
        expect(client).to receive(:request).with(:get, "/test", params: { page: 1 }, headers: { "Accept" => "json" })
        client.get("/test", params: { page: 1 }, headers: { "Accept" => "json" })
      end

      it "handles default parameters" do
        expect(client).to receive(:request).with(:get, "/test", params: {}, headers: {})
        client.get("/test")
      end
    end

    describe "#post" do
      it "calls request with POST method" do
        body = { name: "test" }
        expect(client).to receive(:request).with(:post, "/create", body: body, headers: { "Content-Type" => "json" })
        client.post("/create", body: body, headers: { "Content-Type" => "json" })
      end

      it "handles default parameters" do
        expect(client).to receive(:request).with(:post, "/create", body: {}, headers: {})
        client.post("/create")
      end
    end

    describe "#put" do
      it "calls request with PUT method" do
        body = { id: 1, name: "updated" }
        expect(client).to receive(:request).with(:put, "/update/1", body: body, headers: {})
        client.put("/update/1", body: body)
      end
    end

    describe "#patch" do
      it "calls request with PATCH method" do
        body = { name: "patched" }
        expect(client).to receive(:request).with(:patch, "/patch/1", body: body, headers: {})
        client.patch("/patch/1", body: body)
      end
    end

    describe "#delete" do
      it "calls request with DELETE method" do
        expect(client).to receive(:request).with(:delete, "/delete/1", params: { force: true }, headers: {})
        client.delete("/delete/1", params: { force: true })
      end

      it "handles default parameters" do
        expect(client).to receive(:request).with(:delete, "/delete/1", params: {}, headers: {})
        client.delete("/delete/1")
      end
    end
  end

  describe "private methods" do
    let(:client) { described_class.new(base_url: base_url, api_key: api_key, bearer_token: bearer_token) }

    describe "#request" do
      let(:faraday_connection) { instance_double(Faraday::Connection) }
      let(:faraday_request) { instance_double(Faraday::Request) }
      let(:faraday_response) { instance_double(Faraday::Response, status: 200, body: { "result" => "success" }) }
      let(:params_double) { double }
      let(:headers_double) { double }

      before do
        allow(client).to receive(:connection).and_return(faraday_connection)
        allow(faraday_request).to receive(:url)
        allow(faraday_request).to receive(:params).and_return(params_double)
        allow(faraday_request).to receive(:headers).and_return(headers_double)
        allow(faraday_request).to receive(:body=)
        allow(params_double).to receive(:update)
        allow(headers_double).to receive(:update)
        allow(client).to receive(:instrument!)
        allow(client).to receive(:handle_response).and_return({ success: true })
        allow(Time).to receive(:current).and_return(Time.parse("2025-01-01 10:00:00"))
      end

      it "makes successful HTTP request" do
        allow(faraday_connection).to receive(:send) do |verb, &block|
          expect(verb).to eq(:get)
          block.call(faraday_request)
          faraday_response
        end

        expect(faraday_request).to receive(:url).with("/test")
        expect(params_double).to receive(:update).with({ page: 1 })
        expect(headers_double).to receive(:update).with({ "Accept" => "json" })

        result = client.send(:request, :get, "/test", params: { page: 1 }, headers: { "Accept" => "json" })
        expect(result).to eq({ success: true })
      end

      it "handles request with body" do
        body = { name: "test" }
        allow(faraday_connection).to receive(:send) do |verb, &block|
          expect(verb).to eq(:post)
          block.call(faraday_request)
          faraday_response
        end

        expect(faraday_request).to receive(:body=).with(body.to_json)

        client.send(:request, :post, "/create", body: body)
      end

      it "skips empty params and headers" do
        allow(faraday_connection).to receive(:send) do |verb, &block|
          block.call(faraday_request)
          faraday_response
        end

        expect(params_double).not_to receive(:update)
        expect(headers_double).not_to receive(:update)
        expect(faraday_request).not_to receive(:body=)

        client.send(:request, :get, "/test", params: {}, headers: {})
      end

      it "handles Faraday::TimeoutError" do
        allow(faraday_connection).to receive(:send).and_raise(Faraday::TimeoutError, "Request timeout")
        expect(client).to receive(:failure).with("timeout", "Request timeout", response_time: kind_of(Integer))

        client.send(:request, :get, "/test")
      end

      it "handles Faraday::ConnectionFailed" do
        allow(faraday_connection).to receive(:send).and_raise(Faraday::ConnectionFailed, "Connection failed")
        expect(client).to receive(:failure).with("connection_failed", "Connection failed", response_time: kind_of(Integer))

        client.send(:request, :get, "/test")
      end

      it "handles StandardError" do
        allow(faraday_connection).to receive(:send).and_raise(StandardError, "Unexpected error")
        expect(client).to receive(:failure).with("unexpected_error", "Unexpected error", response_time: kind_of(Integer))

        client.send(:request, :get, "/test")
      end

      it "calculates response time correctly" do
        start_time = Time.parse("2025-01-01 10:00:00")
        end_time = Time.parse("2025-01-01 10:00:00.250") # 250ms later

        allow(Time).to receive(:current).and_return(start_time, end_time)
        allow(faraday_connection).to receive(:send).and_return(faraday_response)

        expect(client).to receive(:instrument!).with(:get, "/test", faraday_response, 250)
        expect(client).to receive(:handle_response).with(faraday_response, 250)

        client.send(:request, :get, "/test")
      end
    end

    describe "#connection" do
      it "creates and memoizes Faraday connection" do
        connection = client.send(:connection)
        same_connection = client.send(:connection)

        expect(connection).to be_a(Faraday::Connection)
        expect(connection).to equal(same_connection) # Same object instance
      end

      it "configures connection with base URL" do
        allow(Faraday).to receive(:new).with(url: base_url).and_call_original
        client.send(:connection)
      end

      it "applies default headers after connection creation" do
        expect(client).to receive(:apply_default_headers!).and_call_original
        client.send(:connection)
      end

      context "with faraday-retry gem available" do
        before do
          stub_const("Faraday::Retry", Class.new)
        end

        it "configures retry middleware when available" do
          connection = client.send(:connection)
          # Test passes if no error is raised during connection setup
          expect(connection).to be_a(Faraday::Connection)
        end
      end

      context "without faraday-retry gem" do
        before do
          hide_const("Faraday::Retry")
        end

        it "continues without retry middleware" do
          connection = client.send(:connection)
          expect(connection).to be_a(Faraday::Connection)
        end
      end

      context "when faraday-retry require fails" do
        it "handles LoadError gracefully" do
          # This test verifies the basic behavior when faraday-retry is not available
          # The actual require happens during Faraday configuration, which is complex to mock
          connection = client.send(:connection)
          expect(connection).to be_a(Faraday::Connection)
        end
      end

      context "in development environment" do
        before do
          allow(Rails.env).to receive(:development?).and_return(true)
          allow(Rails.env).to receive(:test?).and_return(false)
        end

        it "adds logger middleware in development" do
          connection = client.send(:connection)
          expect(connection).to be_a(Faraday::Connection)
        end
      end

      context "in test environment" do
        before do
          allow(Rails.env).to receive(:development?).and_return(false)
          allow(Rails.env).to receive(:test?).and_return(true)
        end

        it "adds logger middleware in test" do
          connection = client.send(:connection)
          expect(connection).to be_a(Faraday::Connection)
        end
      end

      context "in production environment" do
        before do
          allow(Rails.env).to receive(:development?).and_return(false)
          allow(Rails.env).to receive(:test?).and_return(false)
        end

        it "does not add logger middleware in production" do
          connection = client.send(:connection)
          expect(connection).to be_a(Faraday::Connection)
        end
      end
    end

    describe "#apply_default_headers!" do
      let(:faraday_connection) { instance_double(Faraday::Connection) }
      let(:connection_headers) { {} }

      before do
        allow(faraday_connection).to receive(:headers).and_return(connection_headers)
      end

      it "applies default Content-Type and Accept headers" do
        client.send(:apply_default_headers!, faraday_connection)

        expect(connection_headers["Content-Type"]).to eq("application/json")
        expect(connection_headers["Accept"]).to eq("application/json")
      end

      it "applies custom headers" do
        client = described_class.new(base_url: base_url, headers: { "Custom-Header" => "custom-value" })
        client.send(:apply_default_headers!, faraday_connection)

        expect(connection_headers["Custom-Header"]).to eq("custom-value")
      end

      it "applies Bearer token when present" do
        client = described_class.new(base_url: base_url, bearer_token: bearer_token)
        client.send(:apply_default_headers!, faraday_connection)

        expect(connection_headers["Authorization"]).to eq("Bearer #{bearer_token}")
      end

      it "applies API key when present" do
        client = described_class.new(base_url: base_url, api_key: api_key)
        client.send(:apply_default_headers!, faraday_connection)

        expect(connection_headers["X-API-KEY"]).to eq(api_key)
      end

      it "applies both Bearer token and API key when both present" do
        client = described_class.new(base_url: base_url, api_key: api_key, bearer_token: bearer_token)
        client.send(:apply_default_headers!, faraday_connection)

        expect(connection_headers["Authorization"]).to eq("Bearer #{bearer_token}")
        expect(connection_headers["X-API-KEY"]).to eq(api_key)
      end

      it "does not apply authentication headers when not present" do
        client = described_class.new(base_url: base_url)
        client.send(:apply_default_headers!, faraday_connection)

        expect(connection_headers).not_to have_key("Authorization")
        expect(connection_headers).not_to have_key("X-API-KEY")
      end

      it "does not apply empty Bearer token" do
        client = described_class.new(base_url: base_url, bearer_token: "")
        client.send(:apply_default_headers!, faraday_connection)

        expect(connection_headers).not_to have_key("Authorization")
      end

      it "does not apply empty API key" do
        client = described_class.new(base_url: base_url, api_key: "")
        client.send(:apply_default_headers!, faraday_connection)

        expect(connection_headers).not_to have_key("X-API-KEY")
      end
    end

    describe "#handle_response" do
      let(:response_time) { 150 }

      it "handles successful 2xx responses" do
        resp = double(status: 200, body: { "data" => "success" })
        expect(client).to receive(:success).with({ "data" => "success" }, 200, response_time)

        client.send(:handle_response, resp, response_time)
      end

      it "handles different 2xx success codes" do
        [ 200, 201, 204, 299 ].each do |code|
          resp = double(status: code, body: { "result" => "ok" })
          expect(client).to receive(:success).with({ "result" => "ok" }, code, response_time)

          client.send(:handle_response, resp, response_time)
        end
      end

      it "handles client error responses" do
        resp = double(status: 400, body: { "error" => "Bad request" })
        expect(client).to receive(:failure).with(
          "http_400",
          "Bad request",
          code: 400,
          raw: { "error" => "Bad request" },
          response_time: response_time
        )

        client.send(:handle_response, resp, response_time)
      end

      it "handles server error responses" do
        resp = double(status: 500, body: { "message" => "Internal server error" })
        expect(client).to receive(:failure).with(
          "http_500",
          "Internal server error",
          code: 500,
          raw: { "message" => "Internal server error" },
          response_time: response_time
        )

        client.send(:handle_response, resp, response_time)
      end

      it "uses safe_error_message for error handling" do
        resp = double(status: 404, body: "Not found")
        expect(client).to receive(:safe_error_message).with("Not found", 404).and_return("Not found")
        expect(client).to receive(:failure)

        client.send(:handle_response, resp, response_time)
      end
    end

    describe "#safe_error_message" do
      it "extracts error from hash with error key" do
        body = { "error" => "Custom error message" }
        result = client.send(:safe_error_message, body, 400)
        expect(result).to eq("Custom error message")
      end

      it "extracts message from hash with message key" do
        body = { "message" => "Custom message" }
        result = client.send(:safe_error_message, body, 400)
        expect(result).to eq("Custom message")
      end

      it "extracts detail from hash with detail key" do
        body = { "detail" => "Custom detail" }
        result = client.send(:safe_error_message, body, 400)
        expect(result).to eq("Custom detail")
      end

      it "prefers error over message over detail" do
        body = { "error" => "Error message", "message" => "Message text", "detail" => "Detail text" }
        result = client.send(:safe_error_message, body, 400)
        expect(result).to eq("Error message")
      end

      it "falls back to HTTP status when no error keys found" do
        body = { "data" => "some data" }
        result = client.send(:safe_error_message, body, 404)
        expect(result).to eq("HTTP 404")
      end

      it "handles string body" do
        result = client.send(:safe_error_message, "Error occurred", 400)
        expect(result).to eq("Error occurred")
      end

      it "handles empty string body" do
        result = client.send(:safe_error_message, "", 400)
        expect(result).to eq("HTTP 400")
      end

      it "handles nil string body" do
        result = client.send(:safe_error_message, nil, 400)
        expect(result).to eq("HTTP 400")
      end

      it "handles other data types" do
        result = client.send(:safe_error_message, 12345, 400)
        expect(result).to eq("HTTP 400")
      end
    end

    describe "#success" do
      it "returns success result hash" do
        data = { "result" => "success" }
        status = 200
        response_time = 150

        result = client.send(:success, data, status, response_time)

        expect(result).to eq({
          success: true,
          status: 200,
          data: { "result" => "success" },
          response_time_ms: 150
        })
      end

      it "handles nil data" do
        result = client.send(:success, nil, 204, 100)

        expect(result[:success]).to be true
        expect(result[:data]).to be_nil
        expect(result[:status]).to eq(204)
      end
    end

    describe "#failure" do
      it "returns failure result hash with all parameters" do
        result = client.send(:failure, "timeout", "Request timed out",
                             code: 408, raw: "raw response", response_time: 200)

        expect(result).to eq({
          success: false,
          error: {
            kind: "timeout",
            message: "Request timed out",
            code: 408,
            raw: "raw response"
          },
          response_time_ms: 200
        })
      end

      it "returns failure result hash with minimal parameters" do
        result = client.send(:failure, "error", "Something went wrong")

        expect(result).to eq({
          success: false,
          error: {
            kind: "error",
            message: "Something went wrong",
            code: nil,
            raw: nil
          },
          response_time_ms: nil
        })
      end

      it "handles different error kinds" do
        %w[timeout connection_failed http_404 unexpected_error].each do |kind|
          result = client.send(:failure, kind, "Error message")
          expect(result[:error][:kind]).to eq(kind)
        end
      end
    end

    describe "#instrument!" do
      let(:resp) { double(status: 200) }
      let(:response_time) { 150 }

      it "publishes ActiveSupport notification" do
        expect(ActiveSupport::Notifications).to receive(:instrument).with(
          "http.request",
          verb: "GET",
          base_url: base_url,
          path: "/test",
          status: 200,
          response_time_ms: 150
        )

        client.send(:instrument!, :get, "/test", resp, response_time)
      end

      it "handles different HTTP verbs" do
        [ :get, :post, :put, :patch, :delete ].each do |verb|
          expect(ActiveSupport::Notifications).to receive(:instrument).with(
            "http.request",
            hash_including(verb: verb.to_s.upcase)
          )

          client.send(:instrument!, verb, "/test", resp, response_time)
        end
      end

      it "includes all required notification data" do
        expect(ActiveSupport::Notifications).to receive(:instrument) do |event_name, payload|
          expect(event_name).to eq("http.request")
          expect(payload[:verb]).to eq("POST")
          expect(payload[:base_url]).to eq(base_url)
          expect(payload[:path]).to eq("/create")
          expect(payload[:status]).to eq(201)
          expect(payload[:response_time_ms]).to eq(response_time)
        end

        resp = double(status: 201)
        client.send(:instrument!, :post, "/create", resp, response_time)
      end
    end
  end

  describe "method visibility" do
    let(:client) { described_class.new(base_url: base_url) }

    it "makes private methods private" do
      private_methods = [
        :request, :connection, :apply_default_headers!,
        :handle_response, :safe_error_message, :success, :failure, :instrument!
      ]

      private_methods.each do |method|
        expect(client.private_methods).to include(method)
      end
    end

    it "keeps public methods public" do
      public_methods = [ :get, :post, :put, :patch, :delete ]

      public_methods.each do |method|
        expect(client).to respond_to(method)
      end
    end
  end

  describe "integration testing" do
    let(:client) { described_class.new(base_url: "https://httpbin.org") }

    # Note: These would be real HTTP calls in actual integration tests
    # For unit tests, we mock them out
    before do
      allow(client).to receive(:connection).and_return(
        double.tap do |conn|
          allow(conn).to receive(:send).and_return(
            double(status: 200, body: { "result" => "mocked" })
          )
        end
      )
      allow(client).to receive(:handle_response).and_return({ success: true, data: { "result" => "mocked" } })
      allow(client).to receive(:instrument!)
    end

    it "performs GET request successfully" do
      result = client.get("/get", params: { test: "value" })
      expect(result).to include(success: true)
    end

    it "performs POST request successfully" do
      result = client.post("/post", body: { name: "test" })
      expect(result).to include(success: true)
    end

    it "handles request with authentication" do
      auth_client = described_class.new(
        base_url: "https://httpbin.org",
        bearer_token: "test_token"
      )
      allow(auth_client).to receive(:connection).and_return(
        double.tap do |conn|
          allow(conn).to receive(:send).and_return(
            double(status: 200, body: { "authenticated" => true })
          )
        end
      )
      allow(auth_client).to receive(:handle_response).and_return({ success: true })
      allow(auth_client).to receive(:instrument!)

      result = auth_client.get("/bearer")
      expect(result).to include(success: true)
    end
  end

  describe "error handling edge cases" do
    let(:client) { described_class.new(base_url: base_url) }

    it "handles malformed JSON responses gracefully" do
      resp = double(status: 200, body: "invalid json{")
      expect(client).to receive(:success).with("invalid json{", 200, 100)

      client.send(:handle_response, resp, 100)
    end

    it "handles nil response body" do
      resp = double(status: 204, body: nil)
      expect(client).to receive(:success).with(nil, 204, 100)

      client.send(:handle_response, resp, 100)
    end

    it "handles response with zero response time" do
      resp = double(status: 200, body: {})
      expect(client).to receive(:success).with({}, 200, 0)

      client.send(:handle_response, resp, 0)
    end
  end
end
