module Ui
  class ChipComponent < ViewComponent::Base
    attr_reader :label, :variant, :removable, :href

    VARIANTS = %i[primary secondary neutral creative accent].freeze

    def initialize(label:, variant: :neutral, removable: false, href: nil)
      @label = label
      @variant = validate_variant(variant)
      @removable = removable
      @href = href
    end

    def call
      content_tag(element_tag, **element_options) do
        concat(content_tag(:span, label, class: "ui-chip__label"))
        if removable
          concat(render_remove_button)
        end
      end
    end

    private

    def element_tag
      href.present? ? :a : :span
    end

    def element_options
      base = { class: css_classes }
      base[:href] = href if href.present?
      base
    end

    def css_classes
      [
        "ui-chip",
        "ui-chip--#{variant}",
        ("ui-chip--removable" if removable),
        ("ui-chip--link" if href.present?)
      ].compact.join(" ")
    end

    def render_remove_button
      content_tag(:button, type: "button", class: "ui-chip__remove", "aria-label": "Remove #{label}") do
        # Using × symbol for remove
        "×"
      end
    end

    def validate_variant(variant)
      variant = variant.to_sym
      VARIANTS.include?(variant) ? variant : :neutral
    end
  end
end
