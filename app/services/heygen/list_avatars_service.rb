class Heygen::ListAvatarsService < Heygen::BaseService
  def call
    return failure_result("No valid Heygen API token found") unless api_token_present?

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

end
