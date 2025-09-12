class PlanningsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_brand
  before_action :set_current_month
  before_action :set_current_strategy

  # Single Responsibility: Planning Display
  # GET /plannings
  def show
    @presenter = Planning::DisplayService.new(
      user: current_user,
      brand: @brand,
      strategy: @current_strategy,
      params: params
    ).call

    @plans = Planning::WeeklyPlansBuilder.call(@current_strategy)
  end

  # GET /plannings/smart_planning
  def smart_planning
    @plans = Planning::WeeklyPlansBuilder.call(@current_strategy)
  end

  private

  # Simplified setup - delegating complex logic to services
  def set_brand
    @brand = Planning::BrandResolver.call(current_user)
  end

  def set_current_month
    result = Planning::MonthResolver.new(params[:month]).call
    @current_month = result.month
    @current_month_display = result.display_month
  end

  def set_current_strategy
    @current_strategy = Planning::StrategyResolver.new(
      brand: @brand,
      month: @current_month,
      plan_id: params[:plan_id]
    ).call

    # Update month if strategy has specific month
    if @current_strategy&.month.present?
      month_result = Planning::MonthResolver.new(@current_strategy.month).call
      @current_month = month_result.month
      @current_month_display = month_result.display_month
    end
  end
end
