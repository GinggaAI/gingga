require "ostruct"

module Reels
  class InitializationService
    def initialize(user:, template:, smart_planning_data: nil)
      @user = user
      @template = template
      @smart_planning_data = smart_planning_data
    end

    def call
      return failure_result(I18n.t("planning.errors.invalid_template")) unless valid_template?

      # Initialize the reel
      reel_result = ReelCreationService.new(user: @user, template: @template).initialize_reel
      return failure_result(reel_result[:error]) unless reel_result[:success]

      @reel = reel_result[:reel]

      # Preload smart planning data if provided
      if @smart_planning_data.present?
        preload_result = SmartPlanningPreloadService.new(
          reel: @reel,
          planning_data: @smart_planning_data,
          current_user: @user
        ).call

        Rails.logger.warn "Smart planning preload failed: #{preload_result.error}" unless preload_result.success?
      end

      # Setup presenter and view
      presenter_result = PresenterService.new(
        reel: @reel,
        template: @template,
        current_user: @user
      ).call

      return failure_result(presenter_result.error) unless presenter_result.success?

      success_result(
        reel: @reel,
        presenter: presenter_result.data[:presenter],
        view_template: presenter_result.data[:view_template]
      )
    rescue StandardError => e
      Rails.logger.error "Reel initialization failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      failure_result(I18n.t("planning.errors.failed_to_initialize_reel_with_error", error: e.message))
    end

    private

    attr_reader :user, :template, :smart_planning_data, :reel

    def valid_template?
      %w[only_avatars avatar_and_video narration_over_7_images one_to_three_videos].include?(@template)
    end

    def success_result(data)
      OpenStruct.new(success?: true, data: data, error: nil)
    end

    def failure_result(error_message)
      OpenStruct.new(success?: false, data: nil, error: error_message)
    end
  end
end
