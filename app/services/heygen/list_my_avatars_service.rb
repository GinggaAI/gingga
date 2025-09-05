module Heygen
  class ListMyAvatarsService < Heygen::BaseService
    def call
      return failure_result("No valid Heygen API token found") unless api_token_present?

      cached_result = Rails.cache.read(cache_key)
      return success_result(cached_result) if cached_result

      groups_response = fetch_avatar_groups
      return failure_result("Failed to fetch avatar groups: #{groups_response.message}") unless groups_response.success?

      custom_groups = filter_custom_groups(groups_response)
      avatars = fetch_avatars_from_groups(custom_groups)

      Rails.cache.write(cache_key, avatars, expires_in: 6.hours)
      success_result(avatars)
    rescue StandardError => e
      failure_result("Error fetching custom avatars: #{e.message}")
    end

    private

    def fetch_avatar_groups
      get(Heygen::Endpoints::LIST_AVATAR_GROUPS)
    end

    def filter_custom_groups(response)
      data = parse_json(response)
      groups = data.dig("avatar_group_list") || []
      groups.reject { |group| group["group_type"].to_s.start_with?("PUBLIC_") }
    end

    def fetch_avatars_from_groups(groups)
      groups.flat_map do |group|
        endpoint = Heygen::Endpoints::LIST_GROUP_AVATARS % group["id"]
        response = get(endpoint)
        next [] unless response.success?

        data = parse_json(response)
        avatars = data.dig("avatar_list") || []

        avatars.map do |avatar|
          {
            id: avatar["id"],
            name: avatar["name"],
            preview_image_url: avatar["image_url"],
            group_id: group["id"],
            group_type: group["group_type"],
            source: "custom"
          }
        end
      end
    end

    def cache_key
      cache_key_for("custom_avatars")
    end
  end
end
