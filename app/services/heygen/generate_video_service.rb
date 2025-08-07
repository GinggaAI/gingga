class Heygen::GenerateVideoService
  include HTTParty
  base_uri "https://api.heygen.com"

  def initialize(user, reel)
    @user = user
    @reel = reel
    @api_token = user.active_token_for("heygen")
  end

  def call
    return failure_result("No valid Heygen API token found") unless @api_token
    return failure_result("Reel is not ready for generation") unless @reel.ready_for_generation?

    payload = build_payload
    response = generate_video(payload)

    if response.success?
      video_data = parse_response(response)
      update_reel_with_video_data(video_data)
      success_result(video_data)
    else
      @reel.update!(status: "failed")
      failure_result("Failed to generate video: #{response.message}")
    end
  rescue StandardError => e
    @reel.update!(status: "failed") if @reel
    failure_result("Error generating video: #{e.message}")
  end

  private

  def generate_video(payload)
    @reel.update!(status: "processing")

    self.class.post("/v2/video/generate", {
      headers: {
        "X-API-KEY" => @api_token.encrypted_token,
        "Content-Type" => "application/json"
      },
      body: payload.to_json
    })
  end

  def build_payload
    scenes = @reel.reel_scenes.ordered.map(&:to_heygen_payload)

    {
      video_inputs: scenes.map.with_index(1) do |scene, index|
        {
          character: {
            type: "avatar",
            avatar_id: scene[:avatar_id],
            avatar_style: "normal"
          },
          voice: {
            type: "text",
            input_text: scene[:script],
            voice_id: scene[:voice_id]
          },
          background: {
            type: "color",
            value: "#ffffff"
          }
        }
      end,
      dimension: {
        width: 1280,
        height: 720
      },
      aspect_ratio: "16:9",
      test: @api_token.mode == "test"
    }
  end

  def parse_response(response)
    data = JSON.parse(response.body)
    {
      video_id: data.dig("data", "video_id"),
      status: "processing"
    }
  end

  def update_reel_with_video_data(video_data)
    @reel.update!(
      heygen_video_id: video_data[:video_id],
      status: "processing"
    )
  end

  def success_result(data)
    { success: true, data: data }
  end

  def failure_result(message)
    { success: false, error: message }
  end
end
