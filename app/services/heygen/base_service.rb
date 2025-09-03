require "net/http"
require "ostruct"

class Heygen::BaseService
  include HTTParty
  base_uri "https://api.heygen.com"

  def initialize(user, **options)
    @user = user
    @api_token = user.active_token_for("heygen")
    @options = options
  end

  protected

  def api_token_present?
    @api_token.present?
  end

  def headers
    {
      "X-API-KEY" => @api_token.encrypted_token,
      "Content-Type" => "application/json"
    }
  end

  def get(path, query: {})
    start_time = Time.current
    response = self.class.get(path, headers: headers, query: query)
    
    # Log API response
    log_api_response(
      endpoint: path,
      request_data: { query: query, headers: headers },
      response: response,
      response_time: ((Time.current - start_time) * 1000).to_i
    )
    
    wrap_response(response)
  rescue => e
    # Log failed API response
    log_api_response(
      endpoint: path,
      request_data: { query: query, headers: headers },
      error: e,
      response_time: ((Time.current - start_time) * 1000).to_i
    )
    
    # Re-raise the exception so it can be handled by the calling service
    # but with a more informative message
    if timeout_error?(e)
      raise StandardError, "Request timeout: #{e.message}"
    else
      raise StandardError, e.message
    end
  end

  def post(path, body: {})
    start_time = Time.current
    json_body = body.is_a?(String) ? body : body.to_json
    response = self.class.post(path, headers: headers, body: json_body)
    
    # Log API response
    log_api_response(
      endpoint: path,
      request_data: { body: json_body, headers: headers },
      response: response,
      response_time: ((Time.current - start_time) * 1000).to_i
    )
    
    wrap_response(response)
  rescue => e
    # Log failed API response
    log_api_response(
      endpoint: path,
      request_data: { body: json_body, headers: headers },
      error: e,
      response_time: ((Time.current - start_time) * 1000).to_i
    )
    
    # Re-raise the exception so it can be handled by the calling service
    # but with a more informative message
    if timeout_error?(e)
      raise StandardError, "Request timeout: #{e.message}"
    else
      raise StandardError, e.message
    end
  end

  def parse_json(response)
    return {} unless response.body
    JSON.parse(response.body)
  rescue JSON::ParserError => e
    Rails.logger.warn "JSON parse error for Heygen API response: #{e.message}"
    { error: "Invalid JSON response" }
  end

  def success_result(data)
    { success: true, data: data }
  end

  def failure_result(message)
    { success: false, error: message }
  end

  def cache_key_for(resource_type)
    "heygen_#{resource_type}_#{@user.id}_#{@api_token.mode}"
  end

  private

  def timeout_error?(exception)
    return false unless defined?(Net::TimeoutError) && defined?(Net::ReadTimeout)
    exception.is_a?(Net::TimeoutError) || exception.is_a?(Net::ReadTimeout)
  end

  def wrap_response(response)
    # Return response as-is for compatibility with existing code
    response
  end

  def create_error_response(message)
    # Create a response object that behaves like HTTParty response but indicates failure
    OpenStruct.new(
      success?: false,
      code: 0,
      message: message,
      body: { error: message }.to_json
    )
  end
  
  def log_api_response(endpoint:, request_data:, response: nil, error: nil, response_time:)
    return unless @user # Only log if we have a user context
    
    if response
      status_code = response.respond_to?(:code) ? response.code : nil
      response_body = response.respond_to?(:body) ? response.body : response.to_s
      success = response.respond_to?(:success?) ? response.success? : (status_code&.between?(200, 299) || false)
      error_message = success ? nil : "HTTP #{status_code}: #{response_body}"
    else
      status_code = nil
      response_body = nil
      success = false
      error_message = error&.message
    end
    
    # Sanitize request data to remove sensitive information
    sanitized_request = request_data.dup
    if sanitized_request.is_a?(Hash) && sanitized_request[:headers]
      sanitized_request[:headers] = sanitized_request[:headers].dup
      sanitized_request[:headers]["X-API-KEY"] = "[REDACTED]" if sanitized_request[:headers]["X-API-KEY"]
    end
    
    ApiResponse.log_api_call(
      provider: "heygen",
      endpoint: endpoint,
      user: @user,
      request_data: sanitized_request,
      response_data: response_body,
      status_code: status_code,
      response_time_ms: response_time,
      success: success,
      error_message: error_message
    )
  end
end
