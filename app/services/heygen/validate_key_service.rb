class Heygen::ValidateKeyService
  include HTTParty
  base_uri "https://api.heygen.com"

  def initialize(token:, mode:)
    @token = token
    @mode = mode
  end

  def call
    response = self.class.get("/v2/avatars", {
      headers: {
        "X-API-KEY" => @token,
        "Content-Type" => "application/json"
      }
    })

    if response.success?
      { valid: true }
    else
      { valid: false, error: "Invalid Heygen API token: #{response.code} - #{response.body}" }
    end
  rescue StandardError => e
    { valid: false, error: "Token validation failed: #{e.message}" }
  end
end
