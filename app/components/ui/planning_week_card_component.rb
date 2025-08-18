module Ui
  class PlanningWeekCardComponent < ViewComponent::Base
    attr_reader :week_number, :start_date, :end_date, :content_count, :goals, :status

    STATUSES = %i[draft scheduled published].freeze

    def initialize(week_number:, start_date:, end_date:, content_count: 0, goals: [], status: :draft)
      @week_number = week_number
      @start_date = start_date
      @end_date = end_date
      @content_count = content_count
      @goals = Array(goals)
      @status = validate_status(status)
    end

    def call
      content_tag(:div, class: css_classes) do
        concat(render_header)
        concat(render_metrics)
        concat(render_goals) if goals.any?
        concat(render_actions)
      end
    end

    private

    def css_classes
      [
        "ui-planning-week-card",
        "ui-planning-week-card--#{status}"
      ].join(" ")
    end

    def render_header
      content_tag(:header, class: "ui-planning-week-card__header") do
        concat(content_tag(:h4, "Week #{week_number}", class: "ui-planning-week-card__title"))
        concat(content_tag(:p, date_range, class: "ui-planning-week-card__date"))
        concat(render_status_badge)
      end
    end

    def render_metrics
      content_tag(:div, class: "ui-planning-week-card__metrics") do
        content_tag(:div, class: "ui-planning-week-card__metric") do
          concat(content_tag(:span, content_count.to_s, class: "ui-planning-week-card__metric-value"))
          concat(content_tag(:span, pluralize_content(content_count), class: "ui-planning-week-card__metric-label"))
        end
      end
    end

    def render_goals
      content_tag(:div, class: "ui-planning-week-card__goals") do
        goals.map do |goal|
          render(Ui::BadgeComponent.new(label: goal.to_s.humanize, variant: :"goal_#{goal}", size: :sm))
        end.join.html_safe
      end
    end

    def render_actions
      content_tag(:div, class: "ui-planning-week-card__actions") do
        case status
        when :draft
          render(Ui::ButtonComponent.new(label: "Plan Week", variant: :primary, size: :sm))
        when :scheduled
          render(Ui::ButtonComponent.new(label: "Edit Plan", variant: :ghost, size: :sm))
        when :published
          render(Ui::ButtonComponent.new(label: "View Results", variant: :secondary, size: :sm))
        end
      end
    end

    def render_status_badge
      variant = case status
      when :draft then :warning
      when :scheduled then :primary
      when :published then :success
      end

      render(Ui::BadgeComponent.new(label: status.to_s.humanize, variant: variant, size: :sm))
    end

    def date_range
      if start_date && end_date
        "#{start_date.strftime('%b %d')} - #{end_date.strftime('%b %d')}"
      else
        "No dates set"
      end
    end

    def pluralize_content(count)
      count == 1 ? "piece" : "pieces"
    end

    def validate_status(status)
      status = status.to_sym
      STATUSES.include?(status) ? status : :draft
    end
  end
end
