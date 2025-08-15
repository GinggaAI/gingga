module Ui
  class ButtonComponent < ViewComponent::Base
    attr_reader :label, :variant, :type, :href, :disabled, :size, :full_width

    VARIANTS = %i[primary ghost warm_gradient cool_gradient secondary].freeze
    SIZES = %i[sm md lg].freeze

    def initialize(label:, variant: :primary, type: :button, href: nil, disabled: false, size: :md, full_width: false)
      @label = label
      @variant = validate_variant(variant)
      @type = type
      @href = href
      @disabled = disabled
      @size = validate_size(size)
      @full_width = full_width
    end

    def call
      content_tag(element_tag, content, **element_options)
    end

    private

    def element_tag
      href.present? ? :a : :button
    end

    def content
      content_present = content_tag(:span, label, class: "ui-button__label")
      block_given? ? super : content_present
    end

    def element_options
      classes = [
        "ui-button",
        "ui-button--#{variant}",
        "ui-button--#{size}",
        ("ui-button--full-width" if full_width),
        ("is-disabled" if disabled)
      ].compact.join(" ")

      base = { class: classes }
      if href.present?
        base.merge!(href: href, role: "button")
      else
        base.merge!(type: type)
        base.merge!(disabled: true) if disabled
      end
      base
    end

    private

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
