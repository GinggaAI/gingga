require "ostruct"

module Reels
  class ScenesPreloadService
    def initialize(reel:, scenes:, current_user:)
      @reel = reel
      @scenes = scenes
      @current_user = current_user
    end

    def call
      Rails.logger.info "🎬 Starting scene preload for reel #{@reel.id}"

      # Ensure reel is saved before creating scenes
      unless @reel.persisted?
        Rails.logger.warn "⚠️ CRITICAL: Reel not persisted yet (should have been saved by ReelCreationService)"
        Rails.logger.info "💾 Emergency save of reel..."
        @reel.save!
        Rails.logger.info "✅ Reel emergency saved with ID: #{@reel.id}"
      else
        Rails.logger.debug "✅ Reel already persisted with ID: #{@reel.id}"
      end

      # Clear existing scenes first
      Rails.logger.info "🧹 Clearing existing scenes..."
      existing_count = @reel.reel_scenes.count
      @reel.reel_scenes.delete_all  # Use delete_all instead of destroy_all for performance
      @reel.reel_scenes.reset  # Reset the association cache
      Rails.logger.info "🧹 Cleared #{existing_count} existing scenes"

      # Get user's default avatar and voice
      default_avatar_id, default_voice_id = resolve_default_avatar_and_voice

      # Process scenes and collect valid ones
      valid_scenes_data = []
      created_scenes = 0

      @scenes.each_with_index do |scene_data, index|
        Rails.logger.debug "🔍 Evaluating scene #{index + 1}: #{scene_data.inspect}"

        if valid_scene_data?(scene_data)
          valid_scenes_data << { data: scene_data, original_index: index }
          Rails.logger.debug "✅ Scene #{index + 1} has valid data"
        else
          Rails.logger.warn "⚠️ Scene #{index + 1} has invalid data - skipping"
        end
      end

      Rails.logger.info "📊 Found #{valid_scenes_data.length} valid scenes out of #{@scenes.length} total"

      # Ensure we have at least 3 valid scenes for templates that require them
      if @reel.requires_scenes? && valid_scenes_data.length < 3
        Rails.logger.warn "⚠️ Only #{valid_scenes_data.length} valid scenes found, but template '#{@reel.template}' requires 3"

        # Fill with default scenes if needed
        while valid_scenes_data.length < 3
          default_scene_data = create_default_scene_data(valid_scenes_data.length + 1)
          valid_scenes_data << { data: default_scene_data, original_index: -1 }
          Rails.logger.info "➕ Added default scene #{valid_scenes_data.length}"
        end
      end

      # Create exactly the number of scenes we need (max 3 for scene-based templates)
      scenes_to_create = @reel.requires_scenes? ? valid_scenes_data.take(3) : valid_scenes_data

      scenes_to_create.each_with_index do |scene_info, index|
        scene_result = create_scene(scene_info[:data], index, default_avatar_id, default_voice_id)
        created_scenes += 1 if scene_result
      end

      Rails.logger.info "🎯 Successfully created #{created_scenes} scenes from #{@scenes.length} input scenes"

      success_result(created_scenes: created_scenes, total_scenes: @scenes.length)
    rescue StandardError => e
      Rails.logger.error "💥 Failed to preload scenes: #{e.message}"
      Rails.logger.error "💥 Backtrace: #{e.backtrace.join("\n")}"
      failure_result("Scene preload failed: #{e.message}")
    end

    private

    attr_reader :reel, :scenes, :current_user

    def resolve_default_avatar_and_voice
      Rails.logger.info "🔍 Resolving default avatar and voice for user #{@current_user.id}"

      # Look for user's active avatars first, then any avatar
      user_avatar = @current_user.avatars.active.first || @current_user.avatars.first
      user_voice = @current_user.voices.active.first || @current_user.voices.first

      Rails.logger.debug "👤 User avatars - Active: #{@current_user.avatars.active.count}, Total: #{@current_user.avatars.count}"
      Rails.logger.debug "🗣️ User voices - Active: #{@current_user.voices.active.count}, Total: #{@current_user.voices.count}"

      default_avatar_id = user_avatar&.avatar_id || "avatar_001"
      default_voice_id = user_voice&.voice_id || "voice_001"

      Rails.logger.info "🎭 Resolved defaults - Avatar: '#{default_avatar_id}' (from #{user_avatar ? 'user' : 'system'}), Voice: '#{default_voice_id}' (from #{user_voice ? 'user' : 'system'})"

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

      Rails.logger.info "🎬 Processing scene #{scene_number} with data: #{scene_data.inspect}"

      # Extract script from various possible fields
      script = scene_data["voiceover"] || scene_data["script"] || scene_data["description"]
      Rails.logger.debug "📝 Extracted script for scene #{scene_number}: '#{script&.truncate(100)}'"

      # Validate script content
      if script.blank?
        Rails.logger.warn "⚠️ Skipping scene #{scene_number}: no script content found in fields: voiceover, script, description"
        return false
      end

      # Clean and validate script
      cleaned_script = script.strip
      if cleaned_script.length < 1
        Rails.logger.warn "⚠️ Skipping scene #{scene_number}: script too short after cleaning: '#{cleaned_script}'"
        return false
      end

      # Use provided IDs or fallback to defaults
      avatar_id = scene_data["avatar_id"].presence || default_avatar_id
      voice_id = scene_data["voice_id"].presence || default_voice_id

      Rails.logger.info "🎭 Scene #{scene_number} setup - Avatar: '#{avatar_id}', Voice: '#{voice_id}', Script length: #{cleaned_script.length}"

      # Validate required fields before creation
      if avatar_id.blank?
        Rails.logger.error "❌ Scene #{scene_number}: avatar_id is blank (provided: '#{scene_data["avatar_id"]}', default: '#{default_avatar_id}')"
        return false
      end

      if voice_id.blank?
        Rails.logger.error "❌ Scene #{scene_number}: voice_id is blank (provided: '#{scene_data["voice_id"]}', default: '#{default_voice_id}')"
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

        Rails.logger.debug "🔧 Creating scene #{scene_number} with params: #{scene_params}"

        created_scene = @reel.reel_scenes.create!(scene_params)

        Rails.logger.info "✅ Successfully created scene #{scene_number} (ID: #{created_scene.id})"
        true
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error "❌ Validation failed for scene #{scene_number}: #{e.record.errors.full_messages.join(', ')}"
        Rails.logger.error "❌ Scene data that failed: #{scene_params}"
        false
      rescue => e
        Rails.logger.error "❌ Unexpected error creating scene #{scene_number}: #{e.message}"
        Rails.logger.error "❌ Scene data: #{scene_params}"
        Rails.logger.error "❌ Backtrace: #{e.backtrace.first(3).join('\n')}"
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
        "voiceover" => "Default scene #{scene_number} content. Please edit this script.",
        "description" => "Default scene #{scene_number}",
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
