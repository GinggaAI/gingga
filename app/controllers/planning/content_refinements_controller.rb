class Planning::ContentRefinementsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_brand
  before_action :set_strategy

  # Single Responsibility: Content Refinement operations
  # POST /planning/content_refinements (full strategy refinement)
  # POST /planning/content_refinements/week (week-specific refinement)
  def create
    target_week = determine_target_week

    result = Planning::ContentRefinementService.new(
      strategy: @strategy,
      target_week: target_week,
      user: current_user
    ).call

    if result.success?
      redirect_to planning_path(plan_id: @strategy.id),
                  notice: result.success_message
    else
      redirect_to planning_path(plan_id: @strategy.id),
                  alert: result.error_message
    end
  rescue StandardError => e
    Rails.logger.error "ContentRefinementsController error: #{e.message}"
    redirect_to planning_path(plan_id: @strategy&.id),
                alert: "Failed to refine content: #{e.message}"
  end

  private

  def determine_target_week
    # Check if this is week-specific refinement
    if action_name == "week" || params[:week_number].present?
      params[:week_number]&.to_i
    else
      nil  # Full strategy refinement
    end
  end

  def set_brand
    @brand = Planning::BrandResolver.call(current_user)
  end

  def set_strategy
    @strategy = Planning::StrategyResolver.new(
      brand: @brand,
      month: params[:month],
      plan_id: params[:plan_id]
    ).call

    unless @strategy
      Rails.logger.warn "ContentRefinementsController: No strategy found (user: #{current_user.id}, plan_id: #{params[:plan_id]})"
      redirect_to planning_path(brand_slug: params[:brand_slug], locale: params[:locale]),
                  alert: "No strategy found to refine."
      nil
    end
  end
end
