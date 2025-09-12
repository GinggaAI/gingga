require "ostruct"

module Reels
  class SmartPlanningPreloadService
    def initialize(reel:, planning_data:, current_user:)
      @reel = reel
      @planning_data = planning_data
      @current_user = current_user
    end

    def call
      Rails.logger.info "🚀 Starting smart planning preload for reel #{@reel.id}"

      parsed_data = parse_planning_data
      if parsed_data.nil?
        Rails.logger.error "❌ Failed to parse planning data"
        return failure_result("Invalid planning data format")
      end

      Rails.logger.info "📊 Planning data keys: #{parsed_data.keys}"
      Rails.logger.debug "📊 Full planning data: #{parsed_data}"

      # Preload scenes FIRST (before updating reel info to avoid validation conflicts)
      if shotplan_scenes_available?(parsed_data)
        scenes = parsed_data["shotplan"]["scenes"]
        Rails.logger.info "🎬 Found #{scenes.length} scenes to preload"
        Rails.logger.debug "🎬 Scene data preview: #{scenes.map.with_index { |s, i| "Scene #{i+1}: #{s.keys}" }}"

        preload_result = preload_scenes(scenes)
        if preload_result.success?
          Rails.logger.info "✅ Scene preload completed successfully"
        else
          Rails.logger.warn "⚠️ Scene preload had issues: #{preload_result.error}"
        end
      else
        Rails.logger.info "📋 No shotplan or scenes found in planning data - skipping scene creation"
        Rails.logger.debug "📋 Shotplan structure: #{parsed_data['shotplan']&.keys}"
      end

      # Update reel basic info AFTER scenes are created (to satisfy validations)
      Rails.logger.info "📝 Updating reel basic info..."
      update_reel_info(parsed_data)

      Rails.logger.info "🎉 Smart planning preload completed"
      success_result("Smart planning data preloaded successfully")
    rescue StandardError => e
      Rails.logger.error "💥 Failed to preload smart planning data: #{e.message}"
      Rails.logger.error "💥 Backtrace: #{e.backtrace.join("\n")}"
      failure_result("Preload failed: #{e.message}")
    end

    private

    attr_reader :reel, :planning_data, :current_user

    def parse_planning_data
      return planning_data if planning_data.is_a?(Hash)

      JSON.parse(planning_data)
    rescue JSON::ParserError => e
      Rails.logger.error "Failed to parse smart planning data: #{e.message}"
      Rails.logger.error "Raw planning data: #{planning_data}"
      nil
    end

    def update_reel_info(parsed_data)
      title = parsed_data["title"] || parsed_data["content_name"]
      description = parsed_data["description"] || parsed_data["post_description"]

      Rails.logger.debug "📝 Updating reel with - Title: '#{title}', Description: '#{description&.truncate(100)}'"

      # Use update instead of update! to avoid triggering scene validations during basic info update
      result = @reel.update(
        title: title,
        description: description
      )

      unless result
        Rails.logger.warn "⚠️ Could not update reel basic info: #{@reel.errors.full_messages.join(', ')}"
        Rails.logger.debug "⚠️ Reel current state - Scenes count: #{@reel.reel_scenes.count}, Template: #{@reel.template}"
      else
        Rails.logger.info "✅ Reel basic info updated successfully"
      end
    end

    def shotplan_scenes_available?(parsed_data)
      parsed_data["shotplan"] &&
      parsed_data["shotplan"]["scenes"] &&
      parsed_data["shotplan"]["scenes"].any?
    end

    def preload_scenes(scenes)
      Rails.logger.info "🎭 Delegating scene preload to ScenesPreloadService..."

      result = ScenesPreloadService.new(
        reel: @reel,
        scenes: scenes,
        current_user: @current_user
      ).call

      if result.success?
        Rails.logger.info "🎯 ScenesPreloadService completed: #{result.data[:created_scenes]} scenes created out of #{result.data[:total_scenes]} provided"
      else
        Rails.logger.error "🔥 ScenesPreloadService failed: #{result.error}"
      end

      result
    end

    def success_result(message)
      OpenStruct.new(success?: true, data: { message: message }, error: nil)
    end

    def failure_result(error_message)
      OpenStruct.new(success?: false, data: nil, error: error_message)
    end
  end
end
