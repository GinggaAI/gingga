# frozen_string_literal: true

module Http
  class BaseClient
    DEFAULT_TIMEOUT = (ENV["HTTP_TIMEOUT"] || 30).to_i
    DEFAULT_OPEN_TIMEOUT = (ENV["HTTP_OPEN_TIMEOUT"] || 5).to_i
    DEFAULT_RETRIES = (ENV["HTTP_RETRIES"] || 2).to_i

    def initialize(base_url:, headers: {}, api_key: nil, bearer_token: nil)
      @base_url = base_url
      @headers = headers
      @api_key = api_key
      @bearer_token = bearer_token
    end

    def get(path, params: {}, headers: {})
      request(:get, path, params: params, headers: headers)
    end

    def post(path, body: {}, headers: {})
      request(:post, path, body: body, headers: headers)
    end

    def put(path, body: {}, headers: {})
      request(:put, path, body: body, headers: headers)
    end

    def patch(path, body: {}, headers: {})
      request(:patch, path, body: body, headers: headers)
    end

    def delete(path, params: {}, headers: {})
      request(:delete, path, params: params, headers: headers)
    end

    private

    def request(verb, path, params: {}, body: nil, headers: {})
      start_time = Time.current

      resp = connection.send(verb) do |req|
        req.url(path)
        req.params.update(params) if params.present?
        req.headers.update(headers) if headers.present?
        req.body = body.to_json if body.present?
      end

      response_time = ((Time.current - start_time) * 1000).to_i
      instrument!(verb, path, resp, response_time)
      handle_response(resp, response_time)
    rescue Faraday::TimeoutError => e
      response_time = ((Time.current - start_time) * 1000).to_i
      failure("timeout", e.message, response_time: response_time)
    rescue Faraday::ConnectionFailed => e
      response_time = ((Time.current - start_time) * 1000).to_i
      failure("connection_failed", e.message, response_time: response_time)
    rescue StandardError => e
      response_time = ((Time.current - start_time) * 1000).to_i
      failure("unexpected_error", e.message, response_time: response_time)
    end

    def connection
      @connection ||= Faraday.new(url: @base_url) do |f|
        # Request middleware
        f.request :json

        # Ensure retry middleware is available
        begin
          require "faraday-retry"
        rescue LoadError
          # Retry middleware not available, continue without it
          Rails.logger.warn "faraday-retry gem not available, skipping retry middleware"
        end

        # Retry logic with exponential backoff (only if middleware is available)
        if defined?(Faraday::Retry)
          f.request :retry,
                    max: DEFAULT_RETRIES,
                    interval: 0.2,
                    interval_randomness: 0.2,
                    backoff_factor: 2,
                    exceptions: [ Faraday::TimeoutError, Faraday::ConnectionFailed ]
        end

        # Response middleware
        f.response :json, content_type: /\bjson$/

        # Logging only in development/test
        if Rails.env.development? || Rails.env.test?
          f.response :logger, Rails.logger, { bodies: true, log_level: :debug }
        end

        # Timeouts
        f.options.timeout = DEFAULT_TIMEOUT
        f.options.open_timeout = DEFAULT_OPEN_TIMEOUT

        # HTTP adapter
        f.adapter Faraday.default_adapter
      end.tap { |conn| apply_default_headers!(conn) }
    end

    def apply_default_headers!(conn)
      conn.headers["Content-Type"] = "application/json"
      conn.headers["Accept"] = "application/json"

      # Apply custom headers
      @headers.each { |key, value| conn.headers[key] = value }

      # Apply authentication headers
      conn.headers["Authorization"] = "Bearer #{@bearer_token}" if @bearer_token.present?
      conn.headers["X-API-KEY"] = @api_key if @api_key.present?
    end

    def handle_response(resp, response_time)
      code = resp.status.to_i
      body = resp.body

      if code.between?(200, 299)
        success(body, code, response_time)
      else
        failure("http_#{code}", safe_error_message(body, code),
                code: code, raw: body, response_time: response_time)
      end
    end

    def safe_error_message(body, code)
      case body
      when Hash
        body["error"] || body["message"] || body["detail"] || "HTTP #{code}"
      when String
        body.presence || "HTTP #{code}"
      else
        "HTTP #{code}"
      end
    end

    def success(data, status, response_time)
      {
        success: true,
        status: status,
        data: data,
        response_time_ms: response_time
      }
    end

    def failure(kind, message, code: nil, raw: nil, response_time: nil)
      {
        success: false,
        error: {
          kind: kind,
          message: message,
          code: code,
          raw: raw
        },
        response_time_ms: response_time
      }
    end

    def instrument!(verb, path, resp, response_time)
      ActiveSupport::Notifications.instrument(
        "http.request",
        verb: verb.to_s.upcase,
        base_url: @base_url,
        path: path,
        status: resp.status,
        response_time_ms: response_time
      )
    end
  end
end
