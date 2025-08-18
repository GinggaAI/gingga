require "rails_helper"

RSpec.describe Ui::CardComponent, type: :component do
  describe "#initialize" do
    it "sets default values" do
      component = described_class.new
      expect(component.instance_variable_get(:@elevated)).to be true
      expect(component.instance_variable_get(:@rounded)).to eq(:lg)
    end

    it "accepts custom elevated and rounded values" do
      component = described_class.new(elevated: false, rounded: :sm)
      expect(component.instance_variable_get(:@elevated)).to be false
      expect(component.instance_variable_get(:@rounded)).to eq(:sm)
    end
  end

  describe "#call" do
    it "renders a div with default styling" do
      result = render_inline(described_class.new) do
        "Card content"
      end

      expect(result).to have_css("div", text: "Card content")
      expect(result).to have_css("div[class*='bg-[var(--surface)]']")
      expect(result).to have_css("div[class*='text-[var(--text)]']")
      expect(result).to have_css("div[class*='rounded-[20px]']")
      expect(result).to have_css("div[class*='p-6']")
      expect(result).to have_css("div[class*='md:p-8']")
      expect(result).to have_css("div[class*='shadow-md']")
    end

    it "renders without elevation when disabled" do
      result = render_inline(described_class.new(elevated: false)) do
        "Card content"
      end

      expect(result).to have_css("div", text: "Card content")
      expect(result.to_s).not_to include("shadow-md")
      expect(result.to_s).not_to include("hover:shadow-lg")
    end

    context "with different rounded values" do
      it "renders small rounded corners" do
        result = render_inline(described_class.new(rounded: :sm)) do
          "Small rounded card"
        end

        expect(result).to have_css("div[class*='rounded-[12px]']")
      end

      it "renders medium rounded corners (default fallback)" do
        result = render_inline(described_class.new(rounded: :md)) do
          "Medium rounded card"
        end

        expect(result).to have_css("div[class*='rounded-[16px]']")
      end

      it "renders large rounded corners" do
        result = render_inline(described_class.new(rounded: :lg)) do
          "Large rounded card"
        end

        expect(result).to have_css("div[class*='rounded-[20px]']")
      end

      it "falls back to medium for invalid rounded value" do
        result = render_inline(described_class.new(rounded: :invalid)) do
          "Invalid rounded card"
        end

        expect(result).to have_css("div[class*='rounded-[16px]']")
      end

      it "converts string rounded value to symbol" do
        result = render_inline(described_class.new(rounded: "sm")) do
          "String rounded card"
        end

        expect(result).to have_css("div[class*='rounded-[12px]']")
      end
    end

    it "renders with elevation effects" do
      result = render_inline(described_class.new(elevated: true)) do
        "Elevated card"
      end

      expect(result.to_s).to include("shadow-md")
      expect(result.to_s).to include("hover:shadow-lg")
      expect(result.to_s).to include("transition-transform")
      expect(result.to_s).to include("hover:-translate-y-0.5")
    end

    it "renders content inside the card" do
      result = render_inline(described_class.new) do
        "<h2>Card Title</h2><p>Card description</p>".html_safe
      end

      expect(result).to have_css("h2", text: "Card Title")
      expect(result).to have_css("p", text: "Card description")
    end
  end

  describe "rounded_class private method" do
    let(:component) { described_class.new }

    it "returns correct classes for each rounded option" do
      expect(component.send(:rounded_class)).to eq("rounded-[20px]") # default :lg

      component.instance_variable_set(:@rounded, :sm)
      expect(component.send(:rounded_class)).to eq("rounded-[12px]")

      component.instance_variable_set(:@rounded, :lg)
      expect(component.send(:rounded_class)).to eq("rounded-[20px]")

      component.instance_variable_set(:@rounded, :md)
      expect(component.send(:rounded_class)).to eq("rounded-[16px]")

      component.instance_variable_set(:@rounded, :unknown)
      expect(component.send(:rounded_class)).to eq("rounded-[16px]")
    end
  end
end
