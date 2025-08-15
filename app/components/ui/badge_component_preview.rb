module Ui
  class BadgeComponentPreview < ViewComponent::Preview
    def default
      render(Ui::BadgeComponent.new(label: "Primary"))
    end

    def variants
      <<~HTML.html_safe
        <div class="space-y-4">
          <div class="flex flex-wrap gap-2">
            #{render(Ui::BadgeComponent.new(label: "Primary", variant: :primary))}
            #{render(Ui::BadgeComponent.new(label: "Secondary", variant: :secondary))}
            #{render(Ui::BadgeComponent.new(label: "Success", variant: :success))}
            #{render(Ui::BadgeComponent.new(label: "Warning", variant: :warning))}
            #{render(Ui::BadgeComponent.new(label: "Danger", variant: :danger))}
          </div>
        </div>
      HTML
    end

    def goal_variants
      <<~HTML.html_safe
        <div class="space-y-4">
          <h4 class="font-medium">Goal Types</h4>
          <div class="flex flex-wrap gap-2">
            #{render(Ui::BadgeComponent.new(label: "Growth", variant: :goal_growth))}
            #{render(Ui::BadgeComponent.new(label: "Retention", variant: :goal_retention))}
            #{render(Ui::BadgeComponent.new(label: "Engagement", variant: :goal_engagement))}
            #{render(Ui::BadgeComponent.new(label: "Activation", variant: :goal_activation))}
            #{render(Ui::BadgeComponent.new(label: "Satisfaction", variant: :goal_satisfaction))}
          </div>
        </div>
      HTML
    end

    def sizes
      <<~HTML.html_safe
        <div class="space-y-4">
          <div class="flex items-center gap-2">
            #{render(Ui::BadgeComponent.new(label: "Small", size: :sm))}
            #{render(Ui::BadgeComponent.new(label: "Medium", size: :md))}
            #{render(Ui::BadgeComponent.new(label: "Large", size: :lg))}
          </div>
        </div>
      HTML
    end
  end
end
