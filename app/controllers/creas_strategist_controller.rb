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
        format.json { render json: { success: false, error: result.error }, status: 422 }
      end
    end
  end

  private

  def find_brand
    @brand = current_user.brands.first

    unless @brand
      respond_to do |format|
        format.html { redirect_to planning_path, alert: "Please create a brand profile first" }
        format.json { render json: { success: false, error: "Please create a brand profile first" }, status: 422 }
      end
      nil # Important: stop execution here
    end
  end

  def serialize_plan(plan)
    {
      id: plan.id,
      status: plan.status,
      strategy_name: plan.strategy_name,
      month: plan.month,
      objective_of_the_month: plan.objective_of_the_month,
      objective_details: plan.objective_details,
      frequency_per_week: plan.frequency_per_week,
      monthly_themes: plan.monthly_themes,
      selected_templates: plan.selected_templates,
      content_distribution: plan.content_distribution,
      weekly_plan: plan.weekly_plan
    }
  end

  def strategy_form_params
    return {} unless params[:strategy_form]

    permitted_params = params.require(:strategy_form).permit(
      :primary_objective,
      :objective_of_the_month,
      :objective_details,
      :frequency_per_week,
      :monthly_themes,
      :selected_templates
    )

    # Parse selected_templates JSON string to array
    if permitted_params[:selected_templates].present?
      begin
        permitted_params[:selected_templates] = JSON.parse(permitted_params[:selected_templates])
      rescue JSON::ParserError
        permitted_params[:selected_templates] = []
      end
    end

    permitted_params
  end
end
