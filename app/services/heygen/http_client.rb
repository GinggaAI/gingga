# frozen_string_literal: true

module Heygen
  class HttpClient < ::Http::BaseClient
    def initialize(user:)
      api_token = user.active_token_for("heygen")

      raise ArgumentError, "No valid Heygen API token found for user" unless api_token&.encrypted_token.present?

      super(
        base_url: ENV.fetch("HEYGEN_API_BASE", "https://api.heygen.com"),
        headers: { "X-Client" => "Gingga/1.0" },
        api_key: api_token.encrypted_token
      )

      @user = user
      @api_token = api_token
    end

    def get_with_logging(path, params: {}, headers: {})
      result = get(path, params: params, headers: headers)
      log_api_call(path, { query: params, headers: sanitize_headers(headers) }, result)
      result
    end

    def post_with_logging(path, body: {}, headers: {})
      result = post(path, body: body, headers: headers)
      log_api_call(path, { body: sanitize_body(body), headers: sanitize_headers(headers) }, result)
      result
    end

    private

    def log_api_call(endpoint, request_data, result)
      return unless defined?(ApiResponse) && @user

      ApiResponse.log_api_call(
        provider: "heygen",
        endpoint: endpoint,
        user: @user,
        request_data: request_data,
        response_data: result[:data],
        status_code: result[:status],
        response_time_ms: result[:response_time_ms],
        success: result[:success],
        error_message: result.dig(:error, :message)
      )
    rescue => e
      Rails.logger.error "Failed to log API call: #{e.message}"
    end

    def sanitize_headers(headers)
      sanitized = headers.dup
      sanitized["X-API-KEY"] = "[REDACTED]" if sanitized.key?("X-API-KEY")
      sanitized
    end

    def sanitize_body(body)
      # For now, return body as-is since HeyGen doesn't typically send sensitive data in request bodies
      # Can be enhanced if needed
      body
    end
  end
end
