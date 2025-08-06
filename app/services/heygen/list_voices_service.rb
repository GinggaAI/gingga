class Heygen::ListVoicesService
  include HTTParty
  base_uri "https://api.heygen.com"

  def initialize(user, filters = {})
    @user = user
    @api_token = user.active_token_for("heygen")
    @filters = filters
  end

  def call
    return failure_result("No valid Heygen API token found") unless @api_token

    cached_result = Rails.cache.read(cache_key)
    return success_result(filter_voices(cached_result)) if cached_result

    response = fetch_voices

    if response.success?
      voices_data = parse_response(response)
      Rails.cache.write(cache_key, voices_data, expires_in: 18.hours)
      success_result(filter_voices(voices_data))
    else
      failure_result("Failed to fetch voices: #{response.message}")
    end
  rescue StandardError => e
    failure_result("Error fetching voices: #{e.message}")
  end

  private

  def fetch_voices
    self.class.get("/v2/voices", {
      headers: {
        "X-API-KEY" => @api_token.encrypted_token,
        "Content-Type" => "application/json"
      }
    })
  end

  def parse_response(response)
    data = JSON.parse(response.body)
    return [] unless data["data"]
    voices = data.dig("data", "voices") || []

    voices.map do |voice|
      {
        id: voice["voice_id"],
        name: voice["name"],
        language: voice["language"],
        gender: voice["gender"],
        age_group: voice["age_group"],
        accent: voice["accent"],
        is_public: voice["is_public"],
        preview_audio_url: voice["preview_audio_url"]
      }
    end
  end

  def filter_voices(voices_data)
    return voices_data unless @filters.any?

    filtered = voices_data

    filtered = filtered.select { |voice| voice[:language] == @filters[:language] } if @filters[:language]
    filtered = filtered.select { |voice| voice[:gender] == @filters[:gender] } if @filters[:gender]
    filtered = filtered.select { |voice| voice[:age_group] == @filters[:age_group] } if @filters[:age_group]
    filtered = filtered.select { |voice| voice[:accent] == @filters[:accent] } if @filters[:accent]

    filtered
  end

  def cache_key
    "heygen_voices_#{@user.id}_#{@api_token.mode}"
  end

  def success_result(data)
    { success: true, data: data }
  end

  def failure_result(message)
    { success: false, error: message }
  end
end
