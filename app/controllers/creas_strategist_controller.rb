class CreasStrategistController < ApplicationController
  before_action :authenticate_user!, unless: -> { Rails.env.test? }
  before_action :find_brand

  def create
    @month = params[:month]&.presence || Date.current.strftime("%Y-%m")

    result = CreateStrategyService.call(
      user: current_user,
      brand: @brand,
      month: @month,
      strategy_params: strategy_form_params
    )

    if result.success?
      respond_to do |format|
        format.html { redirect_to planning_path(plan_id: result.plan.id), status: :see_other }
        format.json {
          render json: {
            success: true,
            plan: serialize_plan(result.plan),
            redirect_url: planning_path(plan_id: result.plan.id)
          }
        }
      end
    else
      respond_to do |format|
        format.html { redirect_to planning_path, alert: result.error }
        format.json { render json: { success: false, error: result.error }, status: :unprocessable_entity }
      end
    end
  end

  private

  def find_brand
    Rails.logger.info "=== DEBUG find_brand ==="
    Rails.logger.info "current_user: #{current_user.inspect}"
    Rails.logger.info "current_user.id: #{current_user&.id}"
    Rails.logger.info "current_user.brands.count: #{current_user&.brands&.count}"

    @brand = current_user.brands.first
    Rails.logger.info "@brand: #{@brand.inspect}"

    unless @brand
      Rails.logger.info "No brand found - responding with error"
      respond_to do |format|
        format.html { redirect_to planning_path, alert: "Please create a brand profile first" }
        format.json { render json: { success: false, error: "Please create a brand profile first" }, status: :unprocessable_entity }
      end
      return # Important: stop execution here
    end

    Rails.logger.info "Brand found: #{@brand.name}"
  end

  def serialize_plan(plan)
    {
      id: plan.id,
      status: plan.status,
      strategy_name: plan.strategy_name,
      month: plan.month,
      objective_of_the_month: plan.objective_of_the_month,
      frequency_per_week: plan.frequency_per_week,
      monthly_themes: plan.monthly_themes,
      content_distribution: plan.content_distribution,
      weekly_plan: plan.weekly_plan
    }
  end

  def strategy_form_params
    return {} unless params[:strategy_form]

    params.require(:strategy_form).permit(
      :primary_objective,
      :objective_of_the_month,
      :objective_details,
      :frequency_per_week,
      :monthly_themes,
      :resources_override
    )
  end
end
