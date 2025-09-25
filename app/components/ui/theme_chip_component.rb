module Ui
  class ThemeChipComponent < ViewComponent::Base
    attr_reader :theme, :selected, :custom, :removable

    def initialize(theme:, selected: false, custom: false, removable: false)
      @theme = theme
      @selected = selected
      @custom = custom
      @removable = removable
    end

    def call
      content_tag(:div, class: css_classes, data: { theme: theme, selected: selected }) do
        chip_content = []

        # Add checkmark for selected themes
        if selected
          chip_content << content_tag(:span, "✓", class: "text-xs")
        end

        chip_content << content_tag(:span, theme)

        # Add remove button for custom themes
        if removable && custom
          chip_content << content_tag(:button, "×",
            class: "ml-1 text-xs hover:text-red-600",
            type: "button",
            data: { action: "remove-theme" }
          )
        end

        safe_join(chip_content)
      end
    end

    private

    def css_classes
      base_classes = [
        "inline-flex", "items-center", "gap-2", "px-3", "py-1.5", "rounded-full",
        "text-sm", "font-medium", "cursor-pointer", "transition-colors",
        "border", "select-none"
      ]

      if selected
        if custom
          base_classes + [ "bg-green-100", "text-green-800", "border-green-300" ]
        else
          base_classes + [ "bg-blue-100", "text-blue-800", "border-blue-300" ]
        end
      else
        base_classes + [ "bg-gray-100", "text-gray-600", "border-gray-300", "hover:bg-gray-200" ]
      end.join(" ")
    end
  end
end
