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
        return failure_result(I18n.t("planning.smart_planning_preload_errors.invalid_planning_data_format"))
      end

      # Preload scenes FIRST (before updating reel info to avoid validation conflicts)
      if shotplan_scenes_available?(parsed_data)
        scenes = parsed_data["shotplan"]["scenes"]
        Rails.logger.info "🎬 Found #{scenes.length} scenes to preload"

        preload_result = preload_scenes(scenes)
        unless preload_result.success?
          Rails.logger.warn "⚠️ Scene preload had issues: #{preload_result.error}"
        end
      end

      # Update reel basic info AFTER scenes are created (to satisfy validations)
      update_reel_info(parsed_data)

      success_result(I18n.t("planning.smart_planning_preload_errors.smart_planning_data_preloaded_successfully"))
    rescue StandardError => e
      Rails.logger.error "💥 Failed to preload smart planning data: #{e.message}"
      Rails.logger.error "💥 Backtrace: #{e.backtrace.join("\n")}"
      failure_result(I18n.t("planning.smart_planning_preload_errors.preload_failed", error: e.message))
    end

    private

    attr_reader :reel, :planning_data, :current_user

    def parse_planning_data
      return planning_data if planning_data.is_a?(Hash)

      JSON.parse(planning_data)
    rescue JSON::ParserError => e
      Rails.logger.error "#{I18n.t('planning.smart_planning_preload_errors.failed_to_parse_smart_planning_data', error: e.message)}"
      Rails.logger.error "Raw planning data: #{planning_data}"
      nil
    end

    def update_reel_info(parsed_data)
      title = parsed_data["title"] || parsed_data["content_name"]
      description = parsed_data["description"] || parsed_data["post_description"]

      # Use update instead of update! to avoid triggering scene validations during basic info update
      result = @reel.update(
        title: title,
        description: description
      )

      unless result
        Rails.logger.warn "⚠️ #{I18n.t('planning.smart_planning_preload_errors.could_not_update_reel_basic_info', errors: @reel.errors.full_messages.join(', '))}"
      end
    end

    def shotplan_scenes_available?(parsed_data)
      parsed_data["shotplan"] &&
      parsed_data["shotplan"]["scenes"] &&
      parsed_data["shotplan"]["scenes"].any?
    end

    def preload_scenes(scenes)
      result = ScenesPreloadService.new(
        reel: @reel,
        scenes: scenes,
        current_user: @current_user
      ).call

      if result.success?
        Rails.logger.info "🎯 Created #{result.data[:created_scenes]} scenes from #{result.data[:total_scenes]} provided"
      else
        Rails.logger.error "🔥 #{I18n.t('planning.smart_planning_preload_errors.scenes_preload_service_failed', error: result.error)}"
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
