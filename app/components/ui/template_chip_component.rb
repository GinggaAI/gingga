module Ui
  class TemplateChipComponent < ViewComponent::Base
    attr_reader :template_key, :template_description, :selected

    def initialize(template_key:, template_description:, selected: false)
      @template_key = template_key
      @template_description = template_description
      @selected = selected
    end

    def call
      content_tag(:div, class: css_classes, data: { template: template_key, selected: selected }) do
        chip_content = []

        # Add checkmark for selected templates
        if selected
          chip_content << content_tag(:span, "✓", class: "text-xs")
        end

        chip_content << content_tag(:div, class: "flex flex-col") do
          template_content = []
          template_content << content_tag(:span, title, class: "font-medium")
          template_content << content_tag(:span, subtitle, class: "text-xs opacity-75")
          safe_join(template_content)
        end

        safe_join(chip_content)
      end
    end

    private

    def css_classes
      base_classes = [
        "inline-flex", "items-center", "gap-2", "px-3", "py-2", "rounded-lg",
        "text-sm", "cursor-pointer", "transition-colors",
        "border", "select-none", "max-w-xs"
      ]

      if selected
        base_classes + [ "bg-purple-100", "text-purple-800", "border-purple-300" ]
      else
        base_classes + [ "bg-gray-100", "text-gray-600", "border-gray-300", "hover:bg-gray-200" ]
      end.join(" ")
    end

    def title
      template_description.split(" - ").first
    end

    def subtitle
      template_description.split(" - ").last
    end
  end
end
