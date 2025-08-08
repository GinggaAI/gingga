module Ui
  class NavComponent < ViewComponent::Base
    def call
      content_tag :header, class: "sticky top-0 z-50 backdrop-blur supports-[backdrop-filter]:bg-black/40" do
        content_tag :nav, class: "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between" do
          safe_join([
            content_tag(:div, "🌀 GINGGA", class: "font-montserrat font-bold text-xl text-[var(--primary)]"),
            content_tag(:button, "Menu", class: "md:hidden text-[var(--text)]", data: { controller: "menu", action: "click->menu#toggle" }),
            content_tag(:div, class: "hidden md:flex items-center gap-6" ) do
              safe_join([
                link_to("Features", "#features", class: link_classes),
                link_to("How It Works", "#how-it-works", class: link_classes),
                link_to("Guides", "#guides", class: link_classes),
                link_to("Pricing", "#pricing", class: link_classes),
                content_tag(:button, "Get Started", type: "button", class: cta_classes, data: { tracking: "nav_cta" })
              ])
            end
          ])
        end
      end
    end

    private

    def link_classes
      "text-[var(--text)] hover:text-[var(--primary)] transition-colors"
    end

    def cta_classes
      "ui-button ui-button--primary px-5 py-2 rounded-full"
    end
  end
end

