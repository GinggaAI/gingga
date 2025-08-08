module Ui
  class FooterComponent < ViewComponent::Base
    def call
      content_tag :footer, class: "bg-black text-white py-12" do
        content_tag :div, class: "max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 text-center" do
          safe_join([
            content_tag(:div, "🌀 GINGGA", class: "font-montserrat font-bold text-3xl mb-4 text-[var(--primary)]"),
            content_tag(:p, "Intelligence in Motion", class: "text-gray-400 mb-6"),
            content_tag(:div, class: "flex justify-center space-x-6 text-sm" ) do
              safe_join([
                link_to("Privacy Policy", "#", class: footer_link),
                link_to("Terms of Service", "#", class: footer_link),
                link_to("Contact", "#", class: footer_link)
              ])
            end
          ])
        end
      end
    end

    private

    def footer_link
      "text-white hover:text-[var(--orange)] transition-colors"
    end
  end
end

