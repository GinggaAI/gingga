module Ui
  class AddCustomThemeChipComponent < ViewComponent::Base
    def call
      content_tag(:div,
        class: css_classes,
        id: "add-custom-theme-chip",
        data: { action: "add-custom-theme" }
      ) do
        content_tag(:span, "+ Add Custom Theme")
      end
    end

    private

    def css_classes
      [
        "inline-flex", "items-center", "gap-2", "px-3", "py-1.5", "rounded-full",
        "text-sm", "font-medium", "cursor-pointer", "transition-colors",
        "border", "border-dashed", "border-gray-400", "text-gray-500",
        "hover:border-gray-600", "hover:text-gray-700"
      ].join(" ")
    end
  end
end
