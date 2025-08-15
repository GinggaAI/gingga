require "rails_helper"

RSpec.describe Ui::NavComponent, type: :component do
  describe "#call" do
    it "renders a header element" do
      result = render_inline(described_class.new)
      expect(result).to have_css("header")
    end

    it "renders with sticky header styling" do
      result = render_inline(described_class.new)
      expect(result).to have_css("header.sticky.top-0.z-50")
      expect(result.to_s).to include('backdrop-blur')
      expect(result.to_s).to include('supports-[backdrop-filter]:bg-black/40')
    end

    it "renders the nav container with proper styling" do
      result = render_inline(described_class.new)
      expect(result).to have_css("nav.max-w-7xl.mx-auto")
      expect(result.to_s).to include('px-4')
      expect(result.to_s).to include('sm:px-6')
      expect(result.to_s).to include('lg:px-8')
      expect(result.to_s).to include('h-16')
      expect(result.to_s).to include('flex')
      expect(result.to_s).to include('items-center')
      expect(result.to_s).to include('justify-between')
    end

    it "renders the GINGGA brand logo" do
      result = render_inline(described_class.new)
      expect(result).to have_css("div", text: "🌀 GINGGA")
      expect(result).to have_css("div.font-montserrat.font-bold.text-xl")
      expect(result).to have_css("div[class*='text-[var(--primary)]']")
    end

    it "renders mobile menu button" do
      result = render_inline(described_class.new)
      expect(result).to have_css("button", text: "Menu")
      expect(result).to have_css("button.md\\:hidden")
      expect(result).to have_css("button[class*='text-[var(--text)]']")
      expect(result).to have_css("button[data-controller='menu']")
      expect(result).to have_css("button[data-action='click->menu#toggle']")
    end

    it "renders desktop navigation links" do
      result = render_inline(described_class.new)

      # Check the desktop nav container
      expect(result).to have_css("div.hidden.md\\:flex.items-center.gap-6")

      # Check individual navigation links
      expect(result).to have_css("a[href='#features']", text: "Features")
      expect(result).to have_css("a[href='#how-it-works']", text: "How It Works")
      expect(result).to have_css("a[href='#guides']", text: "Guides")
      expect(result).to have_css("a[href='#pricing']", text: "Pricing")
    end

    it "renders CTA button" do
      result = render_inline(described_class.new)
      expect(result).to have_css("button", text: "Get Started")
      expect(result).to have_css("button[type='button']")
      expect(result).to have_css("button[data-tracking='nav_cta']")
      expect(result).to have_css("button.ui-button.ui-button--primary")
    end

    it "applies correct link styling" do
      result = render_inline(described_class.new)

      nav_links = result.css("a[href^='#']")
      nav_links.each do |link|
        expect(link['class']).to include('text-[var(--text)]')
        expect(link['class']).to include('hover:text-[var(--primary)]')
        expect(link['class']).to include('transition-colors')
      end
    end

    it "applies correct CTA button styling" do
      result = render_inline(described_class.new)

      cta_button = result.css("button[data-tracking='nav_cta']").first
      expect(cta_button['class']).to include('ui-button')
      expect(cta_button['class']).to include('ui-button--primary')
      expect(cta_button['class']).to include('px-5')
      expect(cta_button['class']).to include('py-2')
      expect(cta_button['class']).to include('rounded-full')
    end

    it "renders all elements in correct hierarchy" do
      result = render_inline(described_class.new)

      # Header contains nav
      expect(result).to have_css("header > nav")

      # Nav contains brand, menu button, and desktop nav
      expect(result).to have_css("header > nav > div", text: "🌀 GINGGA")
      expect(result).to have_css("header > nav > button", text: "Menu")
      expect(result).to have_css("header > nav > div.hidden.md\\:flex")
    end

    it "has proper responsive behavior" do
      result = render_inline(described_class.new)

      # Mobile menu button is hidden on desktop
      expect(result).to have_css("button.md\\:hidden")

      # Desktop nav is hidden on mobile
      expect(result).to have_css("div.hidden.md\\:flex")

      # Responsive padding
      expect(result.to_s).to include('px-4')
      expect(result.to_s).to include('sm:px-6')
      expect(result.to_s).to include('lg:px-8')
    end
  end

  describe "private methods" do
    let(:component) { described_class.new }

    describe "#link_classes" do
      it "returns the correct CSS classes for navigation links" do
        expected_classes = "text-[var(--text)] hover:text-[var(--primary)] transition-colors"
        expect(component.send(:link_classes)).to eq(expected_classes)
      end
    end

    describe "#cta_classes" do
      it "returns the correct CSS classes for CTA button" do
        expected_classes = "ui-button ui-button--primary px-5 py-2 rounded-full"
        expect(component.send(:cta_classes)).to eq(expected_classes)
      end
    end
  end

  describe "accessibility" do
    it "uses semantic header and nav elements" do
      result = render_inline(described_class.new)
      expect(result).to have_css("header")
      expect(result).to have_css("nav")
    end

    it "has proper button attributes" do
      result = render_inline(described_class.new)

      # Menu button
      expect(result).to have_css("button[data-controller='menu']")
      expect(result).to have_css("button[data-action='click->menu#toggle']")

      # CTA button
      expect(result).to have_css("button[type='button']")
      expect(result).to have_css("button[data-tracking='nav_cta']")
    end

    it "has proper link attributes" do
      result = render_inline(described_class.new)

      # All navigation links should have valid href attributes
      expect(result).to have_link("Features", href: "#features")
      expect(result).to have_link("How It Works", href: "#how-it-works")
      expect(result).to have_link("Guides", href: "#guides")
      expect(result).to have_link("Pricing", href: "#pricing")
    end
  end
end
