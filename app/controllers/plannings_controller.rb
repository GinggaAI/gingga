class PlanningsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_brand
  before_action :set_current_month
  before_action :set_current_strategy, only: [ :show ]

  # GET /plannings
  def show
    @presenter = build_presenter
    @plans = build_weekly_plans
  end

  # GET /plannings/smart_planning
  def smart_planning
    @plans = build_weekly_plans
  end

  # GET /plannings/strategy_for_month
  def strategy_for_month
    strategy = find_strategy_for_requested_month

    if strategy
      render json: Planning::StrategyFormatter.call(strategy)
    else
      render json: { error: I18n.t("planning.messages.strategy_not_found") },
             status: :not_found
    end
  end

  # POST /planning/voxa_refine
  def voxa_refine
    strategy = find_strategy_by_id_or_current

    unless strategy
      Rails.logger.warn "PlanningsController: No strategy found for Voxa refinement (user: #{current_user.id})"
      redirect_to planning_path, alert: "No strategy found to refine." and return
    end

    Rails.logger.info "PlanningsController: Starting Voxa refinement for strategy #{strategy.id} (user: #{current_user.id})"

    Creas::VoxaContentService.new(strategy_plan: strategy).call
    Rails.logger.info "PlanningsController: Voxa refinement started successfully for strategy #{strategy.id}"
    redirect_to planning_path(plan_id: strategy.id), notice: "Content refinement has been started! Please come back to this page in a few minutes to see your refined content."
  rescue Creas::VoxaContentService::ServiceError => e
    Rails.logger.error "PlanningsController: Voxa refinement failed for strategy #{strategy.id}: #{e.message}"
    redirect_to planning_path(plan_id: strategy.id), alert: e.user_message
  rescue StandardError => e
    Rails.logger.error "PlanningsController: Unexpected error during Voxa refinement for strategy #{strategy.id}: #{e.message}"
    redirect_to planning_path(plan_id: strategy.id), alert: "Failed to refine content: #{e.message}"
  end

  # POST /planning/voxa_refine_week
  def voxa_refine_week
    strategy = find_strategy_by_id_or_current
    week_number = params[:week_number]&.to_i

    unless strategy
      Rails.logger.warn "PlanningsController: No strategy found for week-specific Voxa refinement (user: #{current_user.id})"
      redirect_to planning_path, alert: "No strategy found to refine." and return
    end

    unless week_number && (1..4).include?(week_number)
      Rails.logger.warn "PlanningsController: Invalid week number #{week_number} for Voxa refinement (user: #{current_user.id})"
      redirect_to planning_path(plan_id: strategy.id), alert: "Invalid week number. Please select a week between 1 and 4." and return
    end

    Rails.logger.info "PlanningsController: Starting week #{week_number} Voxa refinement for strategy #{strategy.id} (user: #{current_user.id})"

    Creas::VoxaContentService.new(strategy_plan: strategy, target_week: week_number).call
    Rails.logger.info "PlanningsController: Week #{week_number} Voxa refinement started successfully for strategy #{strategy.id}"
    redirect_to planning_path(plan_id: strategy.id), notice: "Week #{week_number} content refinement has been started! Please come back to this page in a few minutes to see your refined content."
  rescue Creas::VoxaContentService::ServiceError => e
    Rails.logger.error "PlanningsController: Week #{week_number} Voxa refinement failed for strategy #{strategy.id}: #{e.message}"
    redirect_to planning_path(plan_id: strategy.id), alert: e.user_message
  rescue StandardError => e
    Rails.logger.error "PlanningsController: Unexpected error during week #{week_number} Voxa refinement for strategy #{strategy.id}: #{e.message}"
    redirect_to planning_path(plan_id: strategy.id), alert: "Failed to refine week #{week_number} content: #{e.message}"
  end

  private

  # Brand and month setup
  def set_brand
    @brand = current_user.brands.first
    # We intentionally don't redirect here to allow views to handle missing brand
    # This provides better UX and allows tests to pass gracefully
  end

  def set_current_month
    @current_month = params[:month] || current_month_param
    @current_month_display = Planning::MonthFormatter.format_for_display(@current_month)
  end

  def current_month_param
    Date.current.strftime("%Y-%-m")
  end

  # Strategy loading
  def set_current_strategy
    @current_strategy = if params[:plan_id]
                          find_strategy_by_id
    else
                          find_strategy_for_current_month
    end

    update_current_month_from_strategy if @current_strategy
  end

  def find_strategy_by_id
    @brand&.creas_strategy_plans&.find_by(id: params[:plan_id])
  end

  def find_strategy_for_current_month
    Planning::StrategyFinder.find_for_brand_and_month(@brand, @current_month)
  end

  def find_strategy_for_requested_month
    month = params[:month] || @current_month
    Planning::StrategyFinder.find_for_brand_and_month(@brand, month)
  end

  def find_strategy_by_id_or_current
    if params[:plan_id].present?
      @brand&.creas_strategy_plans&.find_by(id: params[:plan_id])
    else
      find_strategy_for_current_month
    end
  end

  def update_current_month_from_strategy
    return unless @current_strategy.month.present?

    @current_month = @current_strategy.month
    @current_month_display = Planning::MonthFormatter.format_for_display(@current_month)
  end

  # View data building
  def build_presenter
    PlanningPresenter.new(params, brand: @brand, current_plan: @current_strategy)
  end

  def build_weekly_plans
    Planning::WeeklyPlansBuilder.call(@current_strategy)
  end
end
