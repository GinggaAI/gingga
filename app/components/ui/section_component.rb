module Ui
  class SectionComponent < ViewComponent::Base
    renders_one :heading
    renders_one :subheading
    renders_many :actions

    def initialize(id: nil, padded: true, background: :default, container: true)
      @id = id
      @padded = padded
      @background = background
      @container = container
    end

    def call
      content_tag :section, id: @id, class: section_classes, data: reveal_data do
        inner = capture do
          concat(header_block)
          concat(content) if content
        end
        @container ? content_tag(:div, inner, class: "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8") : inner
      end
    end

    private

    def reveal_data
      { controller: "reveal" }
    end

    def section_classes
      classes = [
        (@padded ? "py-16 md:py-24" : nil),
        background_class
      ].compact
      classes.join(" ")
    end

    def background_class
      case @background.to_sym
      when :ink
        "bg-[var(--bg)] text-[var(--text)]"
      when :surface
        "bg-[var(--surface)] text-[var(--text)]"
      else
        "bg-transparent"
      end
    end

    def header_block
      return unless heading || subheading || actions.present?

      content_tag :div, class: "text-center mb-12" do
        concat(content_tag(:h2, heading, class: "font-montserrat font-bold text-3xl md:text-5xl")) if heading
        concat(content_tag(:p, subheading, class: "text-lg md:text-xl text-[var(--muted)] mt-4")) if subheading
        if actions.present?
          concat(content_tag(:div, safe_join(actions), class: "mt-6 flex items-center justify-center gap-3"))
        end
      end
    end
  end
end

