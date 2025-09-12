class Planning::StrategiesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_brand

  # Single Responsibility: Strategy API endpoints
  # GET /planning/strategies/for_month
  def for_month
    strategy = Planning::StrategyFinder.find_for_brand_and_month(@brand, params[:month])

    if strategy
      render json: Planning::StrategyFormatter.call(strategy)
    else
      render json: { error: I18n.t("planning.messages.strategy_not_found") },
             status: :not_found
    end
  end

  private

  def set_brand
    @brand = Planning::BrandResolver.call(current_user)
  end
end
