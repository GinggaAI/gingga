module Reels
  class SmartPlanningControllerService
    def initialize(reel:, smart_planning_data:, current_user:)
      @reel = reel
      @smart_planning_data = smart_planning_data
      @current_user = current_user
    end

    def call
      return success_result if @smart_planning_data.blank?

      planning_data = parse_planning_data
      return failure_result(I18n.t("planning.smart_planning_errors.invalid_planning_data_format")) unless planning_data

      apply_basic_info(planning_data)
      apply_scenes(planning_data) if planning_data["shotplan"]&.dig("scenes")

      success_result
    rescue StandardError => e
      Rails.logger.error "🚨 Smart planning preload failed: #{e.message}"
      failure_result(I18n.t("planning.smart_planning_errors.failed_to_preload_planning_data", error: e.message))
    end

    private

    def parse_planning_data
      JSON.parse(@smart_planning_data)
    rescue JSON::ParserError => e
      Rails.logger.error "❌ #{I18n.t('planning.smart_planning_errors.invalid_json_in_smart_planning_data', error: e.message)}"
      nil
    end

    def apply_basic_info(planning_data)
      @reel.title = planning_data["title"] || planning_data["content_name"]
      @reel.description = planning_data["description"] || planning_data["post_description"]
    end

    def apply_scenes(planning_data)
      scenes = planning_data["shotplan"]["scenes"]
      Rails.logger.info "🎬 Processing #{scenes.length} scenes"

      # Clear existing built scenes (for unsaved reel)
      @reel.reel_scenes.clear

      # Get default avatar/voice IDs
      defaults = get_default_avatar_voice

      created_scenes = 0
      scenes.each_with_index do |scene_data, index|
        if build_scene(scene_data, index + 1, defaults)
          created_scenes += 1
        end
      end

      Rails.logger.info "🎬 Built #{created_scenes}/#{scenes.length} scenes"
    end

    def get_default_avatar_voice
      user_avatar = @current_user.avatars.active.first || @current_user.avatars.first
      user_voice = @current_user.voices.active.first || @current_user.voices.first

      {
        avatar_id: user_avatar&.avatar_id || "avatar_001",
        voice_id: user_voice&.voice_id || "voice_001"
      }
    end

    def build_scene(scene_data, scene_number, defaults)
      script = extract_script(scene_data)
      return false if script.blank?

      @reel.reel_scenes.build(
        scene_number: scene_number,
        avatar_id: scene_data["avatar_id"].presence || defaults[:avatar_id],
        voice_id: scene_data["voice_id"].presence || defaults[:voice_id],
        script: script.strip,
        video_type: "avatar"
      )

      true
    rescue StandardError => e
      Rails.logger.error "❌ #{I18n.t('planning.smart_planning_errors.failed_to_build_scene', scene_number: scene_number, error: e.message)}"
      false
    end

    def extract_script(scene_data)
      scene_data["voiceover"] || scene_data["script"] || scene_data["description"]
    end

    def success_result
      { success: true, error: nil }
    end

    def failure_result(error_message)
      { success: false, error: error_message }
    end
  end
end
