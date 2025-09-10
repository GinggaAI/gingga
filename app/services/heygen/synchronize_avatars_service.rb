class Heygen::SynchronizeAvatarsService
  def initialize(user:, group_url: nil)
    @user = user
    @group_url = group_url
  end

  def call
    list_result = fetch_avatars

    return failure_result("Failed to fetch avatars from HeyGen: #{list_result[:error]}") unless list_result[:success]

    avatars_data = list_result[:data] || []
    raw_response = build_raw_response(avatars_data)

    synchronized_avatars = []

    avatars_data.each do |avatar_data|
      avatar = sync_avatar(avatar_data, raw_response)
      synchronized_avatars << avatar if avatar
    end

    success_result(data: {
      synchronized_count: synchronized_avatars.size,
      avatars: synchronized_avatars.map(&:to_api_format)
    })
  rescue StandardError => e
    failure_result("Error synchronizing avatars: #{e.message}")
  end

  private

  def fetch_avatars
    if @group_url.present?

      # Parse the group URL to extract group_id
      url_parser = Heygen::GroupUrlParserService.new(url: @group_url)
      parse_result = url_parser.call

      return parse_result unless parse_result[:success]

      group_id = parse_result[:data][:group_id]
      result = Heygen::ListGroupAvatarsService.new(user: @user, group_id: group_id).call
      result
    else
      # Use the original service to fetch all avatars
      result = Heygen::ListAvatarsService.new(@user).call
        result
    end
  end

  def sync_avatar(avatar_data, raw_response)
    avatar_attributes = {
      user: @user,
      avatar_id: avatar_data[:id] || avatar_data["id"],
      name: avatar_data[:name] || avatar_data["name"] || avatar_data[:avatar_name] || avatar_data["avatar_name"],
      provider: "heygen",
      status: "active",
      preview_image_url: avatar_data[:preview_image_url] || avatar_data["preview_image_url"],
      gender: avatar_data[:gender] || avatar_data["gender"],
      is_public: avatar_data[:is_public] || avatar_data["is_public"] || false,
      raw_response: raw_response
    }

    # Find existing avatar or create new one
    avatar = Avatar.find_or_initialize_by(
      user: @user,
      avatar_id: avatar_attributes[:avatar_id],
      provider: "heygen"
    )

    # Update attributes
    avatar.assign_attributes(avatar_attributes)

    if avatar.save
      avatar
    else
      Rails.logger.error "Failed to sync avatar #{avatar_attributes[:avatar_id]}: #{avatar.errors.full_messages.join(', ')}"
      nil
    end
  end

  def build_raw_response(avatars_data)
    {
      "code" => 100,
      "data" => {
        "avatars" => avatars_data
      }
    }.to_json
  end

  def success_result(data:)
    OpenStruct.new(success?: true, data: data, error: nil)
  end

  def failure_result(error_message)
    OpenStruct.new(success?: false, data: nil, error: error_message)
  end
end
