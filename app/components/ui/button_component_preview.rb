module Ui
  class ButtonComponentPreview < ViewComponent::Preview
    def default
      render(Ui::ButtonComponent.new(label: "Primary Action"))
    end

    def disabled
      render(Ui::ButtonComponent.new(label: "Disabled", disabled: true))
    end

    def as_link
      render(Ui::ButtonComponent.new(label: "Go to Docs", href: "/doc/frontend.md"))
    end
  end
end

