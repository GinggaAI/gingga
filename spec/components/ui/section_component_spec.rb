require "rails_helper"

RSpec.describe Ui::SectionComponent, type: :component do
  describe "#initialize" do
    it "sets default values" do
      component = described_class.new
      expect(component.instance_variable_get(:@id)).to be_nil
      expect(component.instance_variable_get(:@padded)).to be true
      expect(component.instance_variable_get(:@background)).to eq(:default)
      expect(component.instance_variable_get(:@container)).to be true
    end

    it "accepts custom values" do
      component = described_class.new(
        id: "test-section",
        padded: false,
        background: :ink,
        container: false
      )

      expect(component.instance_variable_get(:@id)).to eq("test-section")
      expect(component.instance_variable_get(:@padded)).to be false
      expect(component.instance_variable_get(:@background)).to eq(:ink)
      expect(component.instance_variable_get(:@container)).to be false
    end
  end

  describe "#call" do
    it "renders a section element with default styling" do
      result = render_inline(described_class.new) do
        "Section content"
      end

      expect(result).to have_css("section", text: "Section content")
      expect(result).to have_css("section[data-controller='reveal']")
      expect(result).to have_css("section[class*='py-16']")
      expect(result).to have_css("section[class*='md:py-24']")
    end

    it "renders with custom id" do
      result = render_inline(described_class.new(id: "custom-section")) do
        "Section content"
      end

      expect(result).to have_css("section#custom-section")
    end

    it "renders without padding when padded is false" do
      result = render_inline(described_class.new(padded: false)) do
        "Section content"
      end

      expect(result).to have_css("section")
      expect(result.to_s).not_to include("py-16")
      expect(result.to_s).not_to include("md:py-24")
    end

    it "renders with container wrapper by default" do
      result = render_inline(described_class.new) do
        "Section content"
      end

      expect(result).to have_css("section > div.max-w-7xl.mx-auto", text: "Section content")
      expect(result).to have_css("div[class*='px-4']")
      expect(result).to have_css("div[class*='sm:px-6']")
      expect(result).to have_css("div[class*='lg:px-8']")
    end

    it "renders without container when container is false" do
      result = render_inline(described_class.new(container: false)) do
        "Section content"
      end

      expect(result).to have_css("section", text: "Section content")
      expect(result).not_to have_css("div.max-w-7xl")
    end

    context "with different background options" do
      it "renders with ink background" do
        result = render_inline(described_class.new(background: :ink)) do
          "Content"
        end

        expect(result).to have_css("section[class*='bg-[var(--bg)]']")
        expect(result).to have_css("section[class*='text-[var(--text)]']")
      end

      it "renders with surface background" do
        result = render_inline(described_class.new(background: :surface)) do
          "Content"
        end

        expect(result).to have_css("section[class*='bg-[var(--surface)]']")
        expect(result).to have_css("section[class*='text-[var(--text)]']")
      end

      it "renders with transparent background by default" do
        result = render_inline(described_class.new(background: :default)) do
          "Content"
        end

        expect(result).to have_css("section[class*='bg-transparent']")
      end

      it "falls back to transparent for unknown background" do
        result = render_inline(described_class.new(background: :unknown)) do
          "Content"
        end

        expect(result).to have_css("section[class*='bg-transparent']")
      end
    end
  end

  describe "slots" do
    it "renders heading slot" do
      result = render_inline(described_class.new) do |component|
        component.with_heading { "Section Title" }
        "Main content"
      end

      expect(result).to have_css("h2.font-montserrat.font-bold", text: "Section Title")
      expect(result).to have_css("div.text-center.mb-12")
    end

    it "renders subheading slot" do
      result = render_inline(described_class.new) do |component|
        component.with_subheading { "Section description" }
        "Main content"
      end

      expect(result).to have_css("p[class*='text-lg']", text: "Section description")
      expect(result).to have_css("p[class*='md:text-xl']")
      expect(result).to have_css("p[class*='text-[var(--muted)]']")
      expect(result).to have_css("p[class*='mt-4']")
    end

    it "renders actions slot" do
      result = render_inline(described_class.new) do |component|
        component.with_action { "<button>Action 1</button>".html_safe }
        component.with_action { "<button>Action 2</button>".html_safe }
        "Main content"
      end

      expect(result).to have_css("button", text: "Action 1")
      expect(result).to have_css("button", text: "Action 2")
      expect(result).to have_css("div.mt-6.flex.items-center.justify-center.gap-3")
    end

    it "renders all slots together" do
      result = render_inline(described_class.new) do |component|
        component.with_heading { "Main Title" }
        component.with_subheading { "Subtitle text" }
        component.with_action { "<button>CTA</button>".html_safe }
        "Section body content"
      end

      expect(result).to have_css("h2", text: "Main Title")
      expect(result).to have_css("p", text: "Subtitle text")
      expect(result).to have_css("button", text: "CTA")
      expect(result).to have_css("section", text: "Section body content")
    end

    it "does not render header block when no header content" do
      result = render_inline(described_class.new) do
        "Just content"
      end

      expect(result).not_to have_css("div.text-center.mb-12")
      expect(result).not_to have_css("h2")
      expect(result).not_to have_css("p[class*='text-[var(--muted)]']")
    end
  end

  describe "private methods" do
    let(:component) { described_class.new }

    describe "#reveal_data" do
      it "returns controller data attribute" do
        expect(component.send(:reveal_data)).to eq({ controller: "reveal" })
      end
    end

    describe "#section_classes" do
      it "returns padding classes by default" do
        classes = component.send(:section_classes)
        expect(classes).to include("py-16")
        expect(classes).to include("md:py-24")
      end

      it "excludes padding classes when padded is false" do
        component.instance_variable_set(:@padded, false)
        classes = component.send(:section_classes)
        expect(classes).not_to include("py-16")
        expect(classes).not_to include("md:py-24")
      end

      it "includes background classes" do
        component.instance_variable_set(:@background, :ink)
        classes = component.send(:section_classes)
        expect(classes).to include("bg-[var(--bg)]")
        expect(classes).to include("text-[var(--text)]")
      end
    end

    describe "#background_class" do
      it "returns ink background classes" do
        component.instance_variable_set(:@background, :ink)
        classes = component.send(:background_class)
        expect(classes).to eq("bg-[var(--bg)] text-[var(--text)]")
      end

      it "returns surface background classes" do
        component.instance_variable_set(:@background, :surface)
        classes = component.send(:background_class)
        expect(classes).to eq("bg-[var(--surface)] text-[var(--text)]")
      end

      it "returns transparent for default background" do
        component.instance_variable_set(:@background, :default)
        classes = component.send(:background_class)
        expect(classes).to eq("bg-transparent")
      end

      it "returns transparent for unknown background" do
        component.instance_variable_set(:@background, :unknown)
        classes = component.send(:background_class)
        expect(classes).to eq("bg-transparent")
      end

      it "converts string background to symbol" do
        component.instance_variable_set(:@background, "ink")
        classes = component.send(:background_class)
        expect(classes).to eq("bg-[var(--bg)] text-[var(--text)]")
      end
    end

    describe "#header_block" do
      it "returns nil when no header content" do
        allow(component).to receive(:heading).and_return(nil)
        allow(component).to receive(:subheading).and_return(nil)
        allow(component).to receive(:actions).and_return([])

        expect(component.send(:header_block)).to be_nil
      end
    end
  end

  describe "accessibility" do
    it "uses semantic section element" do
      result = render_inline(described_class.new) do
        "Content"
      end

      expect(result).to have_css("section")
    end

    it "includes proper heading hierarchy" do
      result = render_inline(described_class.new) do |component|
        component.with_heading { "Section Heading" }
        "Content"
      end

      expect(result).to have_css("h2", text: "Section Heading")
    end

    it "provides reveal controller for animations" do
      result = render_inline(described_class.new) do
        "Content"
      end

      expect(result).to have_css("section[data-controller='reveal']")
    end
  end

  describe "responsive behavior" do
    it "includes responsive padding classes" do
      result = render_inline(described_class.new) do
        "Content"
      end

      expect(result.to_s).to include("py-16")
      expect(result.to_s).to include("md:py-24")
    end

    it "includes responsive container classes" do
      result = render_inline(described_class.new) do
        "Content"
      end

      expect(result.to_s).to include("px-4")
      expect(result.to_s).to include("sm:px-6")
      expect(result.to_s).to include("lg:px-8")
    end

    it "includes responsive text classes in header" do
      result = render_inline(described_class.new) do |component|
        component.with_heading { "Title" }
        component.with_subheading { "Subtitle" }
        "Content"
      end

      expect(result.to_s).to include("text-3xl")
      expect(result.to_s).to include("md:text-5xl")
      expect(result.to_s).to include("text-lg")
      expect(result.to_s).to include("md:text-xl")
    end
  end
end
