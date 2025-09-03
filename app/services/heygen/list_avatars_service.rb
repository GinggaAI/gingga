class Heygen::ListAvatarsService < Heygen::BaseService
  def call
    return failure_result("No valid Heygen API token found") unless api_token_present?

    # In development mode, return mock data for manual testing when using development tokens
    if Rails.env.development?
      token_value = @api_token&.encrypted_token
      if token_value&.match?(/\A(hg_|test_|demo_)/i)
        Rails.logger.info "HeyGen ListAvatarsService returning mock data for development environment"
        
        # Log the mock API response
        mock_response_data = {
          "code" => 100,
          "data" => {
            "avatars" => mock_avatars_data.map do |avatar|
              {
                "avatar_id" => avatar[:id],
                "avatar_name" => avatar[:name],
                "preview_image_url" => avatar[:preview_image_url],
                "gender" => avatar[:gender],
                "is_public" => avatar[:is_public]
              }
            end
          }
        }
        
        ApiResponse.log_api_call(
          provider: "heygen",
          endpoint: Heygen::Endpoints::LIST_AVATARS,
          user: @user,
          request_data: { query: {}, headers: { "X-API-KEY" => "[REDACTED]" } },
          response_data: mock_response_data,
          status_code: 200,
          response_time_ms: 0,
          success: true,
          error_message: nil
        )
        
        return success_result(mock_avatars_data)
      end
    end

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
    get(Heygen::Endpoints::LIST_AVATARS)
  end

  def parse_response(response)
    data = parse_json(response)
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
    cache_key_for("avatars")
  end

  def mock_avatars_data
    [
      {
        id: "heygen_avatar_demo_1",
        name: "Professional Female Avatar",
        preview_image_url: "https://via.placeholder.com/400x600/4F46E5/FFFFFF?text=Female+Avatar",
        gender: "female",
        is_public: true
      },
      {
        id: "heygen_avatar_demo_2", 
        name: "Business Male Avatar",
        preview_image_url: "https://via.placeholder.com/400x600/059669/FFFFFF?text=Male+Avatar",
        gender: "male",
        is_public: true
      },
      {
        id: "heygen_avatar_demo_3",
        name: "Casual Speaker Avatar",
        preview_image_url: "https://via.placeholder.com/400x600/DC2626/FFFFFF?text=Speaker+Avatar",
        gender: "female",
        is_public: false
      }
    ]
  end
end
