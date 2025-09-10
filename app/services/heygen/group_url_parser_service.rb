class Heygen::GroupUrlParserService
  def initialize(url:)
    @url = url
  end

  def call
    return failure_result("URL is required") if @url.blank?

    begin
      parsed_uri = URI.parse(@url.strip)

      # Validate that it's a HeyGen URL
      unless valid_heygen_url?(parsed_uri)
        return failure_result("Invalid HeyGen URL. Expected format: https://app.heygen.com/avatars?groupId=...")
      end

      # Parse query parameters
      query_params = CGI.parse(parsed_uri.query || "")
      group_id = query_params["groupId"]&.first

      if group_id.blank?
        return failure_result("groupId parameter not found in URL")
      end

      # Validate groupId format (should be a hex string)
      unless valid_group_id?(group_id)
        return failure_result("Invalid groupId format")
      end

      success_result(group_id: group_id)
    rescue URI::InvalidURIError
      failure_result("Invalid URL format")
    rescue StandardError => e
      failure_result("Error parsing URL: #{e.message}")
    end
  end

  private

  def valid_heygen_url?(parsed_uri)
    parsed_uri.scheme == "https" &&
      parsed_uri.host == "app.heygen.com" &&
      parsed_uri.path == "/avatars"
  end

  def valid_group_id?(group_id)
    # HeyGen group IDs are hex strings, typically 24+ characters
    group_id.match?(/\A[a-f0-9]{20,}\z/i)
  end

  def success_result(group_id:)
    {
      success: true,
      data: { group_id: group_id },
      error: nil
    }
  end

  def failure_result(error_message)
    {
      success: false,
      data: nil,
      error: error_message
    }
  end
end
