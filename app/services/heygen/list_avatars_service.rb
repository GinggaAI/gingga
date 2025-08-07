class Heygen::ListAvatarsService
  include HTTParty
  base_uri "https://api.heygen.com"

  def initialize(user)
    @user = user
    @api_token = user.active_token_for("heygen")
  end

  def call
    return failure_result("No valid Heygen API token found") unless @api_token

    cached_result = Rails.cache.read(cache_key)
    return success_result(cached_result) if cached_result

    response = fetch_avatars

    if response.success?
      avatars_data = parse_response(response)
      Rails.cache.write(cache_key, avatars_data, expires_in: 18.hours)
      success_result(avatars_data)
    else
      failure_result("Failed to fetch avatars: #{response.message}")
    end
  rescue StandardError => e
    failure_result("Error fetching avatars: #{e.message}")
  end

  private

  def fetch_avatars
    self.class.get("/v2/avatars", {
      headers: {
        "X-API-KEY" => @api_token.encrypted_token,
        "Content-Type" => "application/json"
      }
    })
  end

  def parse_response(response)
    data = JSON.parse(response.body)
    return [] unless data["data"]

    avatars = data.dig("data", "avatars") || []
    avatars.map do |avatar|
      {
        id: avatar["avatar_id"],
        name: avatar["avatar_name"],
        preview_image_url: avatar["preview_image_url"],
        gender: avatar["gender"],
        is_public: avatar["is_public"]
      }
    end
  end

  def cache_key
    "heygen_avatars_#{@user.id}_#{@api_token.mode}"
  end

  def success_result(data)
    { success: true, data: data }
  end

  def failure_result(message)
    { success: false, error: message }
  end
end
