require "ostruct"

class Heygen::BaseService
  def initialize(user, **options)
    @user = user
    @api_token = user.active_token_for("heygen")
    @options = options
    
    if @api_token.present?
      begin
        @http_client = Heygen::HttpClient.new(user: user)
      rescue ArgumentError => e
        @http_client = nil
        @initialization_error = e.message
      end
    else
      @http_client = nil
      @initialization_error = "No valid Heygen API token found"
    end
  end

  protected

  def api_token_present?
    @api_token.present? && @http_client.present?
  end

  def initialization_error
    @initialization_error
  end

  def get(path, query: {})
    return create_error_response(initialization_error) unless @http_client
    
    result = @http_client.get_with_logging(path, params: query)
    wrap_faraday_response(result)
  rescue => e
    handle_http_error(e)
  end

  def post(path, body: {})
    return create_error_response(initialization_error) unless @http_client
    
    result = @http_client.post_with_logging(path, body: body)
    wrap_faraday_response(result)
  rescue => e
    handle_http_error(e)
  end

  def parse_json(response)
    # With Faraday's json middleware, response data is already parsed
    case response
    when Hash
      response
    when String
      JSON.parse(response)
    else
      response || {}
    end
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

  def wrap_faraday_response(result)
    # Create a response object compatible with existing HTTParty-style code
    if result[:success]
      OpenStruct.new(
        success?: true,
        code: result[:status],
        status: result[:status],
        body: result[:data],
        message: "OK"
      )
    else
      error = result[:error]
      OpenStruct.new(
        success?: false,
        code: error[:code] || 0,
        status: error[:code] || 0,
        body: error[:raw] || { error: error[:message] },
        message: error[:message] || "Request failed"
      )
    end
  end

  def create_error_response(message)
    OpenStruct.new(
      success?: false,
      code: 0,
      status: 0,
      message: message,
      body: { error: message }
    )
  end

  def handle_http_error(exception)
    case exception
    when ArgumentError
      create_error_response(exception.message)
    else
      create_error_response("HTTP request failed: #{exception.message}")
    end
  end
  
end
