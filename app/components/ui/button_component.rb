module Ui
  class ButtonComponent < ViewComponent::Base
    attr_reader :label, :variant, :type, :href, :disabled

    def initialize(label:, variant: :primary, type: :button, href: nil, disabled: false)
      @label = label
      @variant = variant.to_sym
      @type = type
      @href = href
      @disabled = disabled
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
  end
end
