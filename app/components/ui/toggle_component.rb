module Ui
  class ToggleComponent < ViewComponent::Base
    attr_reader :name, :checked, :label, :description, :disabled

    def initialize(name:, checked: false, label:, description: nil, disabled: false)
      @name = name
      @checked = checked
      @label = label
      @description = description
      @disabled = disabled
    end

    def call
      content_tag(:div, class: "ui-toggle") do
        concat(render_input)
        concat(render_label)
      end
    end

    private

    def render_input
      tag(:input, {
        type: "checkbox",
        id: input_id,
        name: name,
        class: "ui-toggle__input",
        checked: checked,
        disabled: disabled,
        "aria-describedby": (description_id if description.present?)
      }.compact)
    end

    def render_label
      content_tag(:label, for: input_id, class: "ui-toggle__label") do
        concat(content_tag(:span, "", class: "ui-toggle__switch", "aria-hidden": true))
        concat(content_tag(:span, label, class: "ui-toggle__text"))
        if description.present?
          concat(content_tag(:span, description, id: description_id, class: "ui-toggle__description"))
        end
      end
    end

    def input_id
      @input_id ||= "toggle_#{name.to_s.parameterize.underscore}"
    end

    def description_id
      @description_id ||= "#{input_id}_description"
    end
  end
end
