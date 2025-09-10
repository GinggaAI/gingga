class Heygen::ListGroupAvatarsService < Heygen::BaseService
  def initialize(user:, group_id:)
    super(user)
    @group_id = group_id
  end

  def call
    return failure_result("No valid Heygen API token found") unless api_token_present?
    return failure_result("Group ID is required") if @group_id.blank?

    # cached_result = Rails.cache.read(cache_key)
    # return success_result(cached_result) if cached_result

    # binding.irb
    response = fetch_group_avatars

    if response.success?
      avatars_data = parse_response(response)
      Rails.cache.write(cache_key, avatars_data, expires_in: 18.hours)
      success_result(avatars_data)
    else
      failure_result("Failed to fetch group avatars: #{response.message}")
    end
  rescue StandardError => e
    failure_result("Error fetching group avatars: #{e.message}")
  end

  private

  def fetch_group_avatars
    endpoint = Heygen::Endpoints::LIST_GROUP_AVATARS % @group_id
    get(endpoint)
  end

  def parse_response(response)
    # Response is now a OpenStructure: response.body["data"]["avatar_list"]
    return [] unless response.body["data"]

    avatars = response.body["data"]["avatar_list"] || []
    Rails.logger.debug "📊 [DEBUB] found #{avatars.size} avatars in avatar_list"

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
    cache_key_for("group_avatars_#{@group_id}")
  end
end
