class CreasStrategyPlansController < ApplicationController
  before_action :authenticate_user!, unless: -> { Rails.env.test? }
  before_action :find_strategy_plan, only: [ :show ]

  def show
    if @strategy_plan
      formatted_plan = Creas::StrategyPlanFormatter.call(@strategy_plan)
      render json: formatted_plan
    else
      render json: { error: "Plan not found" }, status: :not_found
    end
  end

  private

  def find_strategy_plan
    @strategy_plan = current_user.brands
                                 .joins(:creas_strategy_plans)
                                 .find_by(creas_strategy_plans: { id: params[:id] })
                                 &.creas_strategy_plans
                                 &.find(params[:id])
  end
end
