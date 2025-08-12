module Ui
  class CardComponent < ViewComponent::Base
    def initialize(elevated: true, rounded: :lg)
      @elevated = elevated
      @rounded = rounded
    end

    def call
      classes = [
        "bg-[var(--surface)] text-[var(--text)]",
        rounded_class,
        "p-6 md:p-8",
        (@elevated ? "shadow-md hover:shadow-lg transition-transform duration-200 ease-out hover:-translate-y-0.5" : nil)
      ].compact.join(" ")
      content_tag :div, class: classes do
        content
      end
    end

    private

    def rounded_class
      case @rounded.to_sym
      when :sm then "rounded-[12px]"
      when :lg then "rounded-[20px]"
      else "rounded-[16px]"
      end
    end
  end
end

