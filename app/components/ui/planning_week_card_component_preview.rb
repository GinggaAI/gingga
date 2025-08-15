module Ui
  class PlanningWeekCardComponentPreview < ViewComponent::Preview
    def draft_week
      render(Ui::PlanningWeekCardComponent.new(
        week_number: 1,
        start_date: Date.current.beginning_of_week,
        end_date: Date.current.beginning_of_week + 6.days,
        content_count: 5,
        goals: [ :growth, :engagement ],
        status: :draft
      ))
    end

    def scheduled_week
      render(Ui::PlanningWeekCardComponent.new(
        week_number: 2,
        start_date: Date.current.beginning_of_week + 1.week,
        end_date: Date.current.beginning_of_week + 1.week + 6.days,
        content_count: 4,
        goals: [ :retention, :activation ],
        status: :scheduled
      ))
    end

    def published_week
      render(Ui::PlanningWeekCardComponent.new(
        week_number: 3,
        start_date: Date.current.beginning_of_week - 1.week,
        end_date: Date.current.beginning_of_week - 1.week + 6.days,
        content_count: 6,
        goals: [ :satisfaction ],
        status: :published
      ))
    end

    def no_goals
      render(Ui::PlanningWeekCardComponent.new(
        week_number: 4,
        start_date: Date.current.beginning_of_week + 2.weeks,
        end_date: Date.current.beginning_of_week + 2.weeks + 6.days,
        content_count: 3,
        goals: [],
        status: :draft
      ))
    end

    def multiple_goals
      render(Ui::PlanningWeekCardComponent.new(
        week_number: 5,
        start_date: Date.current.beginning_of_week + 3.weeks,
        end_date: Date.current.beginning_of_week + 3.weeks + 6.days,
        content_count: 7,
        goals: [ :growth, :engagement, :retention, :activation ],
        status: :draft
      ))
    end
  end
end
