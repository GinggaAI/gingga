module Ui
  class ToggleComponentPreview < ViewComponent::Preview
    def default
      render(Ui::ToggleComponent.new(
        name: "ai_avatar",
        label: "Use AI Avatars",
        description: "Enable AI-generated human avatars for talking head scenes"
      ))
    end

    def checked
      render(Ui::ToggleComponent.new(
        name: "notifications",
        label: "Email Notifications",
        description: "Receive updates about your content generation",
        checked: true
      ))
    end

    def disabled
      render(Ui::ToggleComponent.new(
        name: "premium_feature",
        label: "Premium Feature",
        description: "This feature requires a premium subscription",
        disabled: true
      ))
    end

    def without_description
      render(Ui::ToggleComponent.new(
        name: "simple_toggle",
        label: "Simple Toggle"
      ))
    end
  end
end
