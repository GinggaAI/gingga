module Planning
  class ContentRefinementService
    Result = Struct.new(:success?, :success_message, :error_message, keyword_init: true)

    def initialize(strategy:, target_week: nil, user:)
      @strategy = strategy
      @target_week = target_week
      @user = user
    end

    def call
      return validation_error unless valid?

      begin
        perform_refinement
        success_result
      rescue Creas::VoxaContentService::ServiceError => e
        log_service_error(e)
        Result.new(success?: false, error_message: e.user_message)
      rescue StandardError => e
        log_unexpected_error(e)
        Result.new(success?: false, error_message: generic_error_message)
      end
    end

    private

    attr_reader :strategy, :target_week, :user

    def valid?
      strategy.present? && valid_week_number?
    end

    def valid_week_number?
      return true if target_week.nil? # Full strategy refinement
      target_week.is_a?(Integer) && (1..4).include?(target_week)
    end

    def validation_error
      return Result.new(success?: false, error_message: I18n.t("planning.errors.no_strategy_to_refine")) unless strategy
      Result.new(success?: false, error_message: I18n.t("planning.errors.invalid_week_number"))
    end

    def perform_refinement
      Creas::VoxaContentService.new(
        strategy_plan: strategy,
        target_week: target_week
      ).call
    end

    def success_result
      message = if target_week
                  I18n.t("planning.messages.week_refinement_started", week: target_week)
      else
                  I18n.t("planning.messages.content_refinement_started")
      end

      Result.new(success?: true, success_message: message)
    end

    def log_service_error(error)
      context = target_week ? "Week #{target_week} " : ""
      Rails.logger.error "ContentRefinementService: #{context}Voxa refinement failed for strategy #{strategy.id}: #{error.message}"
    end

    def log_unexpected_error(error)
      context = target_week ? "week #{target_week} " : ""
      Rails.logger.error "ContentRefinementService: Unexpected error during #{context}Voxa refinement for strategy #{strategy.id}: #{error.message}"
    end

    def generic_error_message
      context = target_week ? "week #{target_week} " : ""
      I18n.t("planning.messages.failed_to_refine_content", context: context)
    end
  end
end
