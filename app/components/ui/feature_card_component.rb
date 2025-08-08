module Ui
  class FeatureCardComponent < ViewComponent::Base
    def initialize(title:, icon_svg:, description:)
      @title = title
      @icon_svg = icon_svg
      @description = description
    end

    def call
      render Ui::CardComponent.new do
        safe_join([
          content_tag(:div, @icon_svg.html_safe, class: "w-12 h-12 mb-4 flex items-center justify-center rounded-lg bg-[var(--cyan)] text-white"),
          content_tag(:h3, @title, class: "font-montserrat font-semibold text-xl mb-2"),
          content_tag(:p, @description, class: "text-[var(--muted)]")
        ])
      end
    end
  end
end

