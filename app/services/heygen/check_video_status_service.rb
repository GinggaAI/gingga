class Heygen::CheckVideoStatusService < Heygen::BaseService
  def initialize(user, reel)
    @reel = reel
    super(user)
  end

  def call
    return failure_result("No valid Heygen API token found") unless api_token_present?
    return failure_result("Reel has no Heygen video ID") unless @reel.heygen_video_id

    response = check_status

    if response.success?
      status_data = parse_response(response)
      update_reel_status(status_data)
      success_result(status_data)
    else
      failure_result("Failed to check video status: #{response.message}")
    end
  rescue StandardError => e
    failure_result("Error checking video status: #{e.message}")
  end

  private

  def check_status
    get(Heygen::Endpoints::VIDEO_STATUS, query: { video_id: @reel.heygen_video_id })
  end

  def parse_response(response)
    data = parse_json(response)
    video_data = data["data"] || {}

    {
      status: map_heygen_status(video_data["status"]),
      video_url: video_data["video_url"],
      thumbnail_url: video_data["thumbnail_url"],
      duration: video_data["duration"],
      created_at: video_data["created_at"]
    }
  end

  def map_heygen_status(heygen_status)
    case heygen_status&.downcase
    when "processing", "pending"
      "processing"
    when "completed", "success"
      "completed"
    when "failed", "error"
      "failed"
    else
      "processing"
    end
  end

  def update_reel_status(status_data)
    update_params = {
      status: status_data[:status]
    }

    if status_data[:status] == "completed"
      update_params.merge!({
        video_url: status_data[:video_url],
        thumbnail_url: status_data[:thumbnail_url],
        duration: status_data[:duration]
      })
    end

    @reel.update!(update_params)
  end
end
