module Ui
  class FormSectionComponent < ViewComponent::Base
    attr_reader :title, :description

    def initialize(title:, description: nil)
      @title = title
      @description = description
    end

    def call
      content_tag(:section, class: "ui-form-section") do
        concat(render_header)
        concat(content_tag(:div, content, class: "ui-form-section__content"))
      end
    end

    private

    def render_header
      content_tag(:header, class: "ui-form-section__header") do
        concat(content_tag(:h3, title, class: "ui-form-section__title"))
        if description.present?
          concat(content_tag(:p, description, class: "ui-form-section__description"))
        end
      end
    end
  end
end
