require "ostruct"

module Reels
  class ScenesPreloadService
    def initialize(reel:, scenes:, current_user:)
      @reel = reel
      @scenes = scenes
      @current_user = current_user
    end

    def call
      # Ensure reel is saved before creating scenes
      unless @reel.persisted?
        @reel.save!
      end

      # Clear existing scenes first
      existing_count = @reel.reel_scenes.count
      @reel.reel_scenes.delete_all  # Use delete_all instead of destroy_all for performance
      @reel.reel_scenes.reset  # Reset the association cache

      # Get user's default avatar and voice
      default_avatar_id, default_voice_id = resolve_default_avatar_and_voice

      # Process scenes and collect valid ones
      valid_scenes_data = []
      created_scenes = 0

      @scenes.each_with_index do |scene_data, index|
        if valid_scene_data?(scene_data)
          valid_scenes_data << { data: scene_data, original_index: index }
        end
      end

      # Ensure we have at least 3 valid scenes for templates that require them
      if @reel.requires_scenes? && valid_scenes_data.length < 3
        # Fill with default scenes if needed
        while valid_scenes_data.length < 3
          default_scene_data = create_default_scene_data(valid_scenes_data.length + 1)
          valid_scenes_data << { data: default_scene_data, original_index: -1 }
        end
      end

      # Create exactly the number of scenes we need (max 3 for scene-based templates)
      scenes_to_create = @reel.requires_scenes? ? valid_scenes_data.take(3) : valid_scenes_data

      scenes_to_create.each_with_index do |scene_info, index|
        scene_result = create_scene(scene_info[:data], index, default_avatar_id, default_voice_id)
        created_scenes += 1 if scene_result
      end

      success_result(created_scenes: created_scenes, total_scenes: @scenes.length)
    rescue StandardError => e
      Rails.logger.error "💥 Failed to preload scenes: #{e.message}"
      Rails.logger.error "💥 Backtrace: #{e.backtrace.join("\n")}"
      failure_result(I18n.t("planning.scene_errors.scene_preload_failed", error: e.message))
    end

    private

    attr_reader :reel, :scenes, :current_user

    def resolve_default_avatar_and_voice
      # Look for user's active avatars first, then any avatar
      user_avatar = @current_user.avatars.active.first || @current_user.avatars.first
      user_voice = @current_user.voices.active.first || @current_user.voices.first

      default_avatar_id = user_avatar&.avatar_id || "avatar_001"
      default_voice_id = user_voice&.voice_id || "voice_001"

      # Validate that defaults are not blank
      if default_avatar_id.blank?
        Rails.logger.error "❌ CRITICAL: default_avatar_id is blank! User avatar: #{user_avatar.inspect}"
        default_avatar_id = "avatar_001"  # Force fallback
      end

      if default_voice_id.blank?
        Rails.logger.error "❌ CRITICAL: default_voice_id is blank! User voice: #{user_voice.inspect}"
        default_voice_id = "voice_001"  # Force fallback
      end

      [ default_avatar_id, default_voice_id ]
    end

    def create_scene(scene_data, index, default_avatar_id, default_voice_id)
      scene_number = index + 1

      # Extract script from various possible fields
      script = scene_data["voiceover"] || scene_data["script"] || scene_data["description"]

      # Validate script content
      if script.blank?
        return false
      end

      # Clean and validate script
      cleaned_script = script.strip
      if cleaned_script.length < 1
        return false
      end

      # Use provided IDs or fallback to defaults
      avatar_id = scene_data["avatar_id"].presence || default_avatar_id
      voice_id = scene_data["voice_id"].presence || default_voice_id

      # Validate required fields before creation
      if avatar_id.blank?
        Rails.logger.error "❌ Scene #{scene_number}: #{I18n.t('planning.scene_errors.avatar_id_blank')}"
        return false
      end

      if voice_id.blank?
        Rails.logger.error "❌ Scene #{scene_number}: #{I18n.t('planning.scene_errors.voice_id_blank')}"
        return false
      end

      begin
        scene_params = {
          scene_number: scene_number,
          avatar_id: avatar_id,
          voice_id: voice_id,
          script: cleaned_script,
          video_type: "avatar"
        }

        @reel.reel_scenes.create!(scene_params)
        true
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error "❌ #{I18n.t('planning.scene_errors.validation_failed_for_scene', scene_number: scene_number, errors: e.record.errors.full_messages.join(', '))}"
        false
      rescue => e
        Rails.logger.error "❌ #{I18n.t('planning.scene_errors.unexpected_error_creating_scene', scene_number: scene_number, error: e.message)}"
        false
      end
    end

    def valid_scene_data?(scene_data)
      # Check if scene has any usable script content
      script = scene_data["voiceover"] || scene_data["script"] || scene_data["description"]
      script.present? && script.strip.length >= 1
    end

    def create_default_scene_data(scene_number)
      {
        "voiceover" => I18n.t("planning.default_scene.voiceover", scene_number: scene_number),
        "description" => I18n.t("planning.default_scene.description", scene_number: scene_number),
        "avatar_id" => nil, # Will use system defaults
        "voice_id" => nil   # Will use system defaults
      }
    end

    def success_result(data)
      OpenStruct.new(success?: true, data: data, error: nil)
    end

    def failure_result(error_message)
      OpenStruct.new(success?: false, data: nil, error: error_message)
    end
  end
end
