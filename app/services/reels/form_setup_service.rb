module Reels
  class FormSetupService
    def initialize(user:, template:, smart_planning_data: nil)
      @user = user
      @template = template
      @smart_planning_data = smart_planning_data
    end

    def call
      # Create unsaved reel for form
      reel = build_reel

      # Build scene structure for scene-based templates
      build_scenes(reel) if scene_based_template?

      # Apply smart planning data if provided
      apply_smart_planning(reel) if @smart_planning_data.present?

      # Setup presenter
      presenter_result = setup_presenter(reel)

      if presenter_result.success?
        success_result(
          reel: reel,
          presenter: presenter_result.data[:presenter],
          view_template: presenter_result.data[:view_template]
        )
      else
        failure_result(presenter_result.error)
      end
    rescue StandardError => e
      failure_result(I18n.t("planning.errors.failed_to_setup_form") + ": #{e.message}")
    end

    private

    def build_reel
      @user.reels.build(template: @template, status: "draft")
    end

    def scene_based_template?
      @template.in?(%w[only_avatars avatar_and_video])
    end

    def build_scenes(reel)
      3.times { |i| reel.reel_scenes.build(scene_number: i + 1) }
    end

    def apply_smart_planning(reel)
      result = SmartPlanningControllerService.new(
        reel: reel,
        smart_planning_data: @smart_planning_data,
        current_user: @user
      ).call

      unless result[:success]
        Rails.logger.warn "⚠️ Smart planning preload failed: #{result[:error]}"
        # Smart planning failures are non-critical and handled gracefully
      end
    end

    def setup_presenter(reel)
      PresenterService.new(
        reel: reel,
        template: @template,
        current_user: @user
      ).call
    end

    def success_result(data)
      { success: true, data: data, error: nil }
    end

    def failure_result(error_message)
      { success: false, data: nil, error: error_message }
    end
  end
end
