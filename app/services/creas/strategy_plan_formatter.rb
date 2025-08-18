module Creas
  class StrategyPlanFormatter
    def initialize(plan)
      @plan = plan
    end

    def self.call(plan)
      new(plan).call
    end

    def call
      return { error: "Plan not found" } unless @plan

      {
        id: @plan.id,
        strategy_name: @plan.strategy_name,
        month: @plan.month,
        objective_of_the_month: @plan.objective_of_the_month,
        frequency_per_week: @plan.frequency_per_week,
        monthly_themes: @plan.monthly_themes,
        weeks: format_weekly_plan
      }
    end

    private

    def format_weekly_plan
      return [] unless @plan.weekly_plan.is_a?(Array)

      @plan.weekly_plan.map.with_index do |week_data, index|
        {
          week_number: index + 1,
          goal: extract_goal_from_week(week_data),
          days: extract_days_from_week(week_data)
        }
      end
    end

    def extract_goal_from_week(week_data)
      week_data.dig("theme") ||
      week_data.dig("goal") ||
      default_goals[rand(default_goals.length)]
    end

    def extract_days_from_week(week_data)
      content_pieces = week_data.dig("content_pieces") ||
                      week_data.dig("posts") ||
                      []

      content_by_day = group_content_by_day(content_pieces)

      weekdays.map do |day|
        {
          day: day,
          contents: content_by_day[day] || []
        }
      end
    end

    def group_content_by_day(content_pieces)
      content_by_day = {}

      content_pieces.each do |piece|
        day_key = normalize_day_name(piece["day"])
        next unless day_key

        content_by_day[day_key] ||= []
        content_by_day[day_key] << (piece["type"] || "Post")
      end

      content_by_day
    end

    def normalize_day_name(day_name)
      return nil unless day_name && !day_name.to_s.empty?

      day_mapping = {
        "Monday" => "Mon",
        "Tuesday" => "Tue",
        "Wednesday" => "Wed",
        "Thursday" => "Thu",
        "Friday" => "Fri",
        "Saturday" => "Sat",
        "Sunday" => "Sun"
      }

      day_mapping[day_name.to_s.capitalize] ||
      day_name.to_s[0..2].capitalize
    end

    def weekdays
      %w[Mon Tue Wed Thu Fri Sat Sun]
    end

    def default_goals
      [ "Awareness", "Engagement", "Launch", "Conversion" ]
    end
  end
end
