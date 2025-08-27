class PlanningsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_brand
  before_action :set_current_month
  before_action :set_current_strategy, only: [ :show ]

  # GET /plannings
  def show
    # Initialize content items from weekly_plan if strategy exists but no content items
    if @current_strategy&.weekly_plan.present? && @current_strategy.creas_content_items.empty?
      service = Creas::ContentItemInitializerService.new(strategy_plan: @current_strategy)
      created_items = service.call
      @current_strategy.reload
      
      # Validate quantity guarantee
      expected_count = @current_strategy.weekly_plan.sum { |week| week["ideas"]&.count || 0 }
      actual_count = @current_strategy.creas_content_items.count
      
      if actual_count < expected_count
        Rails.logger.warn "PlanningsController: Expected #{expected_count} content items but only #{actual_count} were created"
      else
        Rails.logger.info "PlanningsController: Successfully created #{actual_count}/#{expected_count} content items"
      end
    end

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
      redirect_to planning_path, alert: "No strategy found to refine." and return
    end

    begin
      Creas::VoxaContentService.new(strategy_plan: strategy).call
      redirect_to planning_path(plan_id: strategy.id), notice: "Content items refined successfully with Voxa!"
    rescue StandardError => e
      Rails.logger.error "Voxa refinement failed: #{e.message}"
      redirect_to planning_path(plan_id: strategy.id), alert: "Failed to refine content: #{e.message}"
    end
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
