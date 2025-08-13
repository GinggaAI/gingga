class CreasStrategistController < ApplicationController
  before_action :authenticate_user!, unless: -> { Rails.env.test? }

  def create
    brand = current_user.brands.find(params.require(:brand_id))
    month = params.require(:month)
    strategy_form = params.permit(:objective_of_the_month, :frequency_per_week, monthly_themes: [], resources_override: {}).to_h.symbolize_keys
    brief = NoctuaBriefAssembler.call(brand: brand, strategy_form: strategy_form)
    plan = Creas::NoctuaStrategyService.new(user: current_user, brief: brief, brand: brand, month: month).call
    render json: plan, status: :created
  rescue => e
    render json: { error: e.message }, status: :unprocessable_content
  end
end
