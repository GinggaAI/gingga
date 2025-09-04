require "ostruct"

class Heygen::ValidateKeyService
  def initialize(token:, mode:)
    @token = token
    @mode = mode
    @base_url = ENV.fetch("HEYGEN_API_BASE", "https://api.heygen.com")
  end

  def call
    return { valid: false, error: "No token provided" } unless @token.present?

    response = get_avatars

    if response[:success]
      { valid: true }
    else
      error = response[:error]
      { valid: false, error: "Invalid Heygen API token: #{error[:message]}" }
    end
  rescue StandardError => e
    { valid: false, error: "Token validation failed: #{e.message}" }
  end

  private

  def get_avatars
    http_client = Http::BaseClient.new(
      base_url: @base_url,
      headers: { "X-Client" => "Gingga/1.0" },
      api_key: @token
    )
    
    http_client.get(Heygen::Endpoints::VALIDATE_KEY)
  end
end
