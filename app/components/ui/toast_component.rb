module Ui
  class ToastComponent < ViewComponent::Base
    attr_reader :message, :variant, :dismissible, :auto_dismiss

    VARIANTS = %i[success warning error info].freeze

    def initialize(message:, variant: :info, dismissible: true, auto_dismiss: true)
      @message = message
      @variant = validate_variant(variant)
      @dismissible = dismissible
      @auto_dismiss = auto_dismiss
    end

    def call
      content_tag(:div, **element_options) do
        concat(render_icon)
        concat(content_tag(:div, message, class: "ui-toast__message"))
        if dismissible
          concat(render_dismiss_button)
        end
      end
    end

    private

    def element_options
      {
        class: css_classes,
        role: "alert",
        "aria-live": "polite",
        data: data_attributes
      }
    end

    def css_classes
      [
        "ui-toast",
        "ui-toast--#{variant}",
        ("ui-toast--dismissible" if dismissible),
        ("ui-toast--auto-dismiss" if auto_dismiss)
      ].compact.join(" ")
    end

    def data_attributes
      { controller: "toast" }
    end

    def render_icon
      icon_symbol = case variant
      when :success then "✓"
      when :warning then "⚠"
      when :error then "✕"
      else "ℹ"
      end

      content_tag(:span, icon_symbol, class: "ui-toast__icon", "aria-hidden": true)
    end

    def render_dismiss_button
      raw('<button type="button" class="ui-toast__dismiss" aria-label="Dismiss notification">×</button>')
    end

    def validate_variant(variant)
      variant = variant.to_sym
      VARIANTS.include?(variant) ? variant : :info
    end
  end
end
