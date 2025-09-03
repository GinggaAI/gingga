require "ostruct"

class Heygen::ValidateKeyService
  include HTTParty
  base_uri "https://api.heygen.com"

  def initialize(token:, mode:)
    @token = token
    @mode = mode
  end

  def call
    # In development mode, allow tokens that look like valid HeyGen tokens for manual testing
    # Bypass validation for development/test tokens or when running manually (not in RSpec)
    if Rails.env.development? && @token.match?(/\A(hg_|test_|demo_)/i)
      Rails.logger.info "HeyGen token validation bypassed for development environment with test token"
      
      # Log the mock validation response
      if defined?(ApiResponse) && @mode.present? && defined?(User)
        begin
          # Try to find user context, but don't fail if we can't
          current_user = User.joins(:api_tokens).where(api_tokens: { encrypted_token: @token, provider: 'heygen' }).first
          if current_user
            ApiResponse.log_api_call(
              provider: "heygen",
              endpoint: Heygen::Endpoints::VALIDATE_KEY,
              user: current_user,
              request_data: { headers: { "X-API-KEY" => "[REDACTED]" } },
              response_data: { "code" => 100, "data" => { "avatars" => [] } },
              status_code: 200,
              response_time_ms: 0,
              success: true,
              error_message: nil
            )
          end
        rescue => e
          Rails.logger.debug "Could not log validation API response: #{e.message}"
        end
      end
      
      return { valid: true }
    end
    
    response = get_avatars

    if response.success?
      { valid: true }
    else
      { valid: false, error: "Invalid Heygen API token: #{response.code} - #{response.body}" }
    end
  rescue StandardError => e
    { valid: false, error: "Token validation failed: #{e.message}" }
  end

  private

  def get_avatars
    self.class.get(Heygen::Endpoints::VALIDATE_KEY, {
      headers: {
        "X-API-KEY" => @token,
        "Content-Type" => "application/json"
      }
    })
  end
end
