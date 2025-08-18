require "rails_helper"

RSpec.describe Ui::BadgeComponent, type: :component do
  describe "#initialize" do
    it "sets default values" do
      component = described_class.new(label: "Test")
      expect(component.label).to eq("Test")
      expect(component.variant).to eq(:primary)
      expect(component.size).to eq(:md)
    end

    it "accepts custom variant and size" do
      component = described_class.new(label: "Test", variant: :success, size: :lg)
      expect(component.variant).to eq(:success)
      expect(component.size).to eq(:lg)
    end

    it "validates variant and falls back to primary for invalid variant" do
      component = described_class.new(label: "Test", variant: :invalid)
      expect(component.variant).to eq(:primary)
    end

    it "validates size and falls back to md for invalid size" do
      component = described_class.new(label: "Test", size: :invalid)
      expect(component.size).to eq(:md)
    end

    it "accepts string variant and converts to symbol" do
      component = described_class.new(label: "Test", variant: "success")
      expect(component.variant).to eq(:success)
    end

    it "accepts string size and converts to symbol" do
      component = described_class.new(label: "Test", size: "lg")
      expect(component.size).to eq(:lg)
    end
  end

  describe "#call" do
    it "renders a span with label and CSS classes" do
      result = render_inline(described_class.new(label: "Primary Badge"))
      expect(result).to have_css("span.ui-badge.ui-badge--primary.ui-badge--md", text: "Primary Badge")
    end

    it "renders with success variant" do
      result = render_inline(described_class.new(label: "Success", variant: :success))
      expect(result).to have_css("span.ui-badge--success", text: "Success")
    end

    it "renders with large size" do
      result = render_inline(described_class.new(label: "Large", size: :lg))
      expect(result).to have_css("span.ui-badge--lg", text: "Large")
    end

    it "renders with small size" do
      result = render_inline(described_class.new(label: "Small", size: :sm))
      expect(result).to have_css("span.ui-badge--sm", text: "Small")
    end

    it "renders with goal variant" do
      result = render_inline(described_class.new(label: "Growth", variant: :goal_growth))
      expect(result).to have_css("span.ui-badge--goal_growth", text: "Growth")
    end
  end

  describe "constants" do
    it "defines valid variants" do
      expected_variants = %i[primary secondary success warning danger goal_growth goal_retention goal_engagement goal_activation goal_satisfaction]
      expect(described_class::VARIANTS).to eq(expected_variants)
    end

    it "defines valid sizes" do
      expected_sizes = %i[sm md lg]
      expect(described_class::SIZES).to eq(expected_sizes)
    end
  end

  describe "all variant and size combinations" do
    described_class::VARIANTS.each do |variant|
      described_class::SIZES.each do |size|
        it "renders #{variant} variant with #{size} size" do
          result = render_inline(described_class.new(label: "Test", variant: variant, size: size))
          expect(result).to have_css("span.ui-badge--#{variant}.ui-badge--#{size}", text: "Test")
        end
      end
    end
  end
end
