module Ui
  class ChipComponentPreview < ViewComponent::Preview
    def default
      render(Ui::ChipComponent.new(label: "Content Type"))
    end

    def variants
      <<~HTML.html_safe
        <div class="space-y-4">
          <div class="flex flex-wrap gap-2">
            #{render(Ui::ChipComponent.new(label: "Primary", variant: :primary))}
            #{render(Ui::ChipComponent.new(label: "Secondary", variant: :secondary))}
            #{render(Ui::ChipComponent.new(label: "Neutral", variant: :neutral))}
            #{render(Ui::ChipComponent.new(label: "Creative", variant: :creative))}
            #{render(Ui::ChipComponent.new(label: "Accent", variant: :accent))}
          </div>
        </div>
      HTML
    end

    def removable
      <<~HTML.html_safe
        <div class="space-y-4">
          <div class="flex flex-wrap gap-2">
            #{render(Ui::ChipComponent.new(label: "Educational", variant: :primary, removable: true))}
            #{render(Ui::ChipComponent.new(label: "Entertainment", variant: :creative, removable: true))}
            #{render(Ui::ChipComponent.new(label: "Trending", variant: :accent, removable: true))}
          </div>
        </div>
      HTML
    end

    def as_link
      render(Ui::ChipComponent.new(
        label: "Clickable Chip",
        variant: :primary,
        href: "#"
      ))
    end

    def content_types
      <<~HTML.html_safe
        <div class="space-y-4">
          <h4 class="font-medium">Content Type Examples</h4>
          <div class="flex flex-wrap gap-2">
            #{render(Ui::ChipComponent.new(label: "Video", variant: :primary))}
            #{render(Ui::ChipComponent.new(label: "Image", variant: :secondary))}
            #{render(Ui::ChipComponent.new(label: "Story", variant: :creative))}
            #{render(Ui::ChipComponent.new(label: "Reel", variant: :accent))}
            #{render(Ui::ChipComponent.new(label: "Carousel", variant: :neutral))}
          </div>
        </div>
      HTML
    end
  end
end
