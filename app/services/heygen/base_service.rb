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
    response = self.class.get(path, headers: headers, query: query)
    wrap_response(response)
  rescue => e
    # Re-raise the exception so it can be handled by the calling service
    # but with a more informative message
    if timeout_error?(e)
      raise StandardError, "Request timeout: #{e.message}"
    else
      raise StandardError, e.message
    end
  end

  def post(path, body: {})
    json_body = body.is_a?(String) ? body : body.to_json
    response = self.class.post(path, headers: headers, body: json_body)
    wrap_response(response)
  rescue => e
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
end
