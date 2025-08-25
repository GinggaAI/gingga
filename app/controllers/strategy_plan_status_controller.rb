class StrategyPlanStatusController < ApplicationController
  before_action :authenticate_user!, unless: -> { Rails.env.test? }

  def show
    @strategy_plan = CreasStrategyPlan.find(params[:id])

    # Ensure user can only access their own strategy plans
    unless @strategy_plan.user == current_user
      render json: { error: "Not authorized" }, status: :forbidden
      return
    end

    respond_to do |format|
      format.json do
        render json: {
          id: @strategy_plan.id,
          status: @strategy_plan.status,
          error_message: @strategy_plan.error_message,
          completed: @strategy_plan.completed?,
          failed: @strategy_plan.failed?,
          plan: @strategy_plan.completed? ? strategy_plan_data(@strategy_plan) : nil
        }
      end
    end
  end

  private

  def strategy_plan_data(plan)
    {
      id: plan.id,
      strategy_name: plan.strategy_name,
      month: plan.month,
      objective_of_the_month: plan.objective_of_the_month,
      frequency_per_week: plan.frequency_per_week,
      monthly_themes: plan.monthly_themes,
      content_distribution: plan.content_distribution,
      weekly_plan: plan.weekly_plan,
      status: plan.status
    }
  end
end
