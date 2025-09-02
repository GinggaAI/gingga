module Planning
  class WeeklyPlansBuilder
    # Constants for magic numbers
    DAYS_PER_WEEK = 7

    # Status priority for determining week status
    STATUS_HIERARCHY = {
      "published" => 4,
      "approved" => 3,
      "ready_for_review" => 3,
      "in_production" => 2,
      "draft" => 1
    }.freeze

    # CREAS pillar to goal mapping
    PILLAR_TO_GOAL = {
      "C" => :growth,
      "R" => :retention,
      "E" => :engagement,
      "A" => :activation,
      "S" => :satisfaction
    }.freeze

    def self.call(strategy_plan)
      new(strategy_plan).call
    end

    def initialize(strategy_plan)
      @strategy_plan = strategy_plan
    end

    def call
      return fallback_plans unless valid_strategy?

      @strategy_plan.weekly_plan.map.with_index do |week_data, index|
        build_week_plan(week_data, index)
      end
    end

    private

    attr_reader :strategy_plan

    def valid_strategy?
      @strategy_plan&.weekly_plan.present?
    end

    def fallback_plans
      [
        {
          week_number: 1,
          start_date: current_month_start,
          end_date: current_month_start + 6.days,
          content_count: 0,
          goals: [],
          status: :needs_strategy,
          ideas: [],
          message: I18n.t("planning.messages.create_first_strategy")
        }
      ]
    end

    def build_week_plan(week_data, index)
      ideas = week_data["ideas"] || []
      week_start = month_start_date + (index * DAYS_PER_WEEK).days

      {
        week_number: week_data["week"] || (index + 1),
        start_date: week_start,
        end_date: week_start + (DAYS_PER_WEEK - 1).days,
        content_count: ideas.size,
        goals: extract_goals(ideas),
        status: determine_status(ideas),
        ideas: ideas,
        publish_cadence: week_data["publish_cadence"] || @strategy_plan.frequency_per_week
      }
    end

    def month_start_date
      @month_start_date ||= parse_strategy_month
    end

    def parse_strategy_month
      return current_month_start unless @strategy_plan.month.present?

      year, month = @strategy_plan.month.split("-")
      return current_month_start unless year && month

      Date.new(year.to_i, month.to_i, 1)
    rescue ArgumentError, NoMethodError, TypeError => e
      Rails.logger.warn "WeeklyPlansBuilder: Failed to parse month '#{month}': #{e.message}"
      current_month_start
    end

    def current_month_start
      Date.current.beginning_of_month
    end

    def extract_goals(ideas)
      pillars = ideas.filter_map { |idea| idea["pilar"] }.uniq
      pillars.filter_map { |pillar| PILLAR_TO_GOAL[pillar] }
    end

    def determine_status(ideas)
      return :needs_content if ideas.empty?

      highest_status = ideas
        .filter_map { |idea| idea["status"] }
        .map { |status| STATUS_HIERARCHY[status] || 0 }
        .max

      case highest_status
      when 4 then :published
      when 3 then :scheduled
      when 2 then :in_production
      else :draft
      end
    end
  end
end
