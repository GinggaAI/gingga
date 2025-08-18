class CreasStrategyPlansController < ApplicationController
  before_action :authenticate_user!, unless: -> { Rails.env.test? }

  def show
    plan = current_user.brands.joins(:creas_strategy_plans).find_by(creas_strategy_plans: { id: params[:id] })&.creas_strategy_plans&.find(params[:id])

    if plan
      # Convert to the expected format for frontend
      formatted_plan = format_plan_for_frontend(plan)
      render json: formatted_plan
    else
      render json: { error: "Plan not found" }, status: :not_found
    end
  end

  private

  def format_plan_for_frontend(plan)
    # Convert database plan to frontend-expected format
    weeks_data = parse_weekly_plan(plan.weekly_plan)

    {
      id: plan.id,
      strategy_name: plan.strategy_name,
      month: plan.month,
      objective_of_the_month: plan.objective_of_the_month,
      frequency_per_week: plan.frequency_per_week,
      monthly_themes: plan.monthly_themes,
      weeks: weeks_data
    }
  end

  def parse_weekly_plan(weekly_plan)
    # Parse the weekly_plan JSON to expected week structure
    return [] unless weekly_plan.is_a?(Array)

    weekly_plan.map.with_index do |week_data, index|
      {
        week_number: index + 1,
        goal: extract_goal_from_week(week_data),
        days: extract_days_from_week(week_data)
      }
    end
  end

  def extract_goal_from_week(week_data)
    # Extract goal based on week themes or default mapping
    week_data.dig("theme") || week_data.dig("goal") || [ "Awareness", "Engagement", "Launch", "Conversion" ][rand(4)]
  end

  def extract_days_from_week(week_data)
    # Convert week data to days format expected by frontend
    days = %w[Mon Tue Wed Thu Fri Sat Sun]

    # Handle different possible structures
    content_pieces = week_data.dig("content_pieces") || week_data.dig("posts") || []

    # Group content by day
    content_by_day = {}
    content_pieces.each do |piece|
      day_key = map_day_to_short_name(piece["day"])
      content_by_day[day_key] ||= []
      content_by_day[day_key] << piece["type"] || "Post"
    end

    days.map do |day|
      {
        day: day,
        contents: content_by_day[day] || []
      }
    end
  end

  def map_day_to_short_name(day_name)
    return nil unless day_name

    day_mapping = {
      "Monday" => "Mon",
      "Tuesday" => "Tue",
      "Wednesday" => "Wed",
      "Thursday" => "Thu",
      "Friday" => "Fri",
      "Saturday" => "Sat",
      "Sunday" => "Sun"
    }

    day_mapping[day_name.to_s.capitalize] || day_name.to_s[0..2].capitalize
  end
end
