module Ui
  class BadgeComponent < ViewComponent::Base
    attr_reader :label, :variant, :size

    VARIANTS = %i[primary secondary success warning danger goal_growth goal_retention goal_engagement goal_activation goal_satisfaction].freeze
    SIZES = %i[sm md lg].freeze

    def initialize(label:, variant: :primary, size: :md)
      @label = label
      @variant = validate_variant(variant)
      @size = validate_size(size)
    end

    def call
      content_tag(:span, label, class: css_classes)
    end

    private

    def css_classes
      [
        "ui-badge",
        "ui-badge--#{variant}",
        "ui-badge--#{size}"
      ].join(" ")
    end

    def validate_variant(variant)
      variant = variant.to_sym
      VARIANTS.include?(variant) ? variant : :primary
    end

    def validate_size(size)
      size = size.to_sym
      SIZES.include?(size) ? size : :md
    end
  end
end
