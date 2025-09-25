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

    def to_h
      call
    end

    def for_voxa
      return { error: "Plan not found" } unless @plan

      {
        strategy: {
          brand_name: @plan.brand_snapshot.dig("name") || @plan.brand&.name || "Unknown",
          month: @plan.month,
          objective_of_the_month: @plan.objective_of_the_month,
          frequency_per_week: @plan.frequency_per_week,
          selected_templates: @plan.selected_templates || [ "only_avatars" ],
          post_types: extract_post_types,
          weekly_plan: format_weekly_plan_for_voxa
        }
      }
    end

    def for_voxa_batch(content_items)
      return { error: "Plan not found" } unless @plan
      return { error: "No content items provided" } if content_items.empty?

      {
        strategy: {
          brand_name: @plan.brand_snapshot.dig("name") || @plan.brand&.name || "Unknown",
          month: @plan.month,
          objective_of_the_month: @plan.objective_of_the_month,
          frequency_per_week: @plan.frequency_per_week,
          selected_templates: @plan.selected_templates || [ "only_avatars" ],
          post_types: extract_post_types
        },
        batch_content: format_content_items_for_voxa_batch(content_items)
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

    def extract_post_types
      return [ "Video", "Image", "Carousel", "Text" ] unless @plan.raw_payload

      post_types = @plan.raw_payload.dig("post_types")
      post_types.is_a?(Array) && post_types.any? ? post_types : [ "Video", "Image", "Carousel", "Text" ]
    end

    def format_weekly_plan_for_voxa
      return [] unless @plan.weekly_plan.is_a?(Array)

      @plan.weekly_plan.map do |week_data|
        {
          week: week_data["week"] || 1,
          ideas: extract_ideas_from_week(week_data)
        }
      end
    end

    def extract_ideas_from_week(week_data)
      ideas = week_data["ideas"] || []
      ideas.map do |idea|
        {
          id: idea["id"],
          title: idea["title"],
          hook: idea["hook"],
          description: idea["description"],
          platform: idea["platform"] || "Instagram Reels",
          pilar: idea["pilar"],
          recommended_template: idea["recommended_template"],
          video_source: idea["video_source"]
        }
      end
    end

    def format_content_items_for_voxa_batch(content_items)
      content_items.map do |item|
        {
          id: item.content_id,
          origin_id: item.origin_id,
          content_name: item.content_name || "Unnamed Content",
          week: item.week,
          pilar: item.pilar,
          platform: item.platform,
          template: item.template,
          video_source: item.video_source,
          status: item.status,
          day_of_the_week: item.day_of_the_week,
          post_description: item.post_description,
          text_base: item.text_base,
          hashtags: item.hashtags,
          meta: item.meta || {}
        }
      end
    end
  end
end
