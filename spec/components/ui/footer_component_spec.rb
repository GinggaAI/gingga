require "rails_helper"

RSpec.describe Ui::FooterComponent, type: :component do
  describe "#call" do
    it "renders a footer element" do
      result = render_inline(described_class.new)
      expect(result).to have_css("footer")
    end

    it "renders with correct styling classes" do
      result = render_inline(described_class.new)
      expect(result).to have_css("footer.bg-black.text-white.py-12")
    end

    it "renders the container with proper styling" do
      result = render_inline(described_class.new)
      expect(result).to have_css("div.max-w-6xl.mx-auto.px-4.sm\\:px-6.lg\\:px-8.text-center")
    end

    it "renders the GINGGA brand name" do
      result = render_inline(described_class.new)
      expect(result).to have_css("div", text: "🌀 GINGGA")
      expect(result).to have_css("div.font-montserrat.font-bold.text-3xl.mb-4")
      expect(result).to have_css("div[class*='text-[var(--primary)]']")
    end

    it "renders the tagline" do
      result = render_inline(described_class.new)
      expect(result).to have_css("p", text: "Intelligence in Motion")
      expect(result).to have_css("p.text-gray-400.mb-6")
    end

    it "renders footer links" do
      result = render_inline(described_class.new)

      expect(result).to have_css("a", text: "Privacy Policy")
      expect(result).to have_css("a", text: "Terms of Service")
      expect(result).to have_css("a", text: "Contact")

      # Check that all links have href="#"
      expect(result).to have_css("a[href='#']", count: 3)
    end

    it "renders links with proper styling" do
      result = render_inline(described_class.new)

      # Check the container for links
      expect(result).to have_css("div.flex.justify-center.space-x-6.text-sm")

      # Check that links have the footer_link class styles
      links = result.css("a")
      links.each do |link|
        expect(link['class']).to include('text-white')
        expect(link['class']).to include('hover:text-[var(--orange)]')
        expect(result.to_s).to include('transition-colors')
      end
    end

    it "renders all elements in correct hierarchy" do
      result = render_inline(described_class.new)

      # Footer contains div
      expect(result).to have_css("footer > div")

      # Container div contains brand, tagline, and links
      expect(result).to have_css("footer > div > div", text: "🌀 GINGGA")
      expect(result).to have_css("footer > div > p", text: "Intelligence in Motion")
      expect(result).to have_css("footer > div > div.flex")
    end

    it "has proper responsive classes" do
      result = render_inline(described_class.new)

      # Check responsive padding classes
      expect(result.to_s).to include('px-4')
      expect(result.to_s).to include('sm:px-6')
      expect(result.to_s).to include('lg:px-8')
    end
  end

  describe "private methods" do
    let(:component) { described_class.new }

    describe "#footer_link" do
      it "returns the correct CSS classes for footer links" do
        expected_classes = "text-white hover:text-[var(--orange)] transition-colors"
        expect(component.send(:footer_link)).to eq(expected_classes)
      end
    end
  end

  describe "accessibility" do
    it "uses semantic footer element" do
      result = render_inline(described_class.new)
      expect(result).to have_css("footer")
    end

    it "has proper link structure" do
      result = render_inline(described_class.new)

      # Each link should be accessible
      expect(result).to have_css("a", minimum: 3)

      # Links should have meaningful text
      expect(result).to have_link("Privacy Policy")
      expect(result).to have_link("Terms of Service")
      expect(result).to have_link("Contact")
    end
  end
end
