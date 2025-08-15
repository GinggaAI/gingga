require "rails_helper"

RSpec.describe Ui::ChipComponent, type: :component do
  describe "#initialize" do
    it "sets default values" do
      component = described_class.new(label: "Test")
      expect(component.label).to eq("Test")
      expect(component.variant).to eq(:neutral)
      expect(component.removable).to be false
      expect(component.href).to be_nil
    end

    it "accepts custom values" do
      component = described_class.new(
        label: "Custom",
        variant: :primary,
        removable: true,
        href: "/path"
      )
      expect(component.label).to eq("Custom")
      expect(component.variant).to eq(:primary)
      expect(component.removable).to be true
      expect(component.href).to eq("/path")
    end

    it "validates variant and falls back to neutral for invalid variant" do
      component = described_class.new(label: "Test", variant: :invalid)
      expect(component.variant).to eq(:neutral)
    end

    it "accepts string variant and converts to symbol" do
      component = described_class.new(label: "Test", variant: "primary")
      expect(component.variant).to eq(:primary)
    end
  end

  describe "#call" do
    it "renders a span by default" do
      result = render_inline(described_class.new(label: "Test Chip"))
      expect(result).to have_css("span.ui-chip.ui-chip--neutral")
      expect(result).to have_css("span.ui-chip__label", text: "Test Chip")
    end

    it "renders as a link when href is provided" do
      result = render_inline(described_class.new(label: "Link Chip", href: "/path"))
      expect(result).to have_css("a.ui-chip.ui-chip--neutral.ui-chip--link[href='/path']")
      expect(result).to have_css("span.ui-chip__label", text: "Link Chip")
    end

    it "renders with different variants" do
      described_class::VARIANTS.each do |variant|
        result = render_inline(described_class.new(label: "Test", variant: variant))
        expect(result).to have_css("span.ui-chip--#{variant}")
      end
    end

    it "renders as removable when removable is true" do
      result = render_inline(described_class.new(label: "Removable", removable: true))
      expect(result).to have_css("span.ui-chip--removable")
      expect(result).to have_css("button.ui-chip__remove[type='button']", text: "×")
      expect(result).to have_css("button[aria-label='Remove Removable']")
    end

    it "does not render remove button when removable is false" do
      result = render_inline(described_class.new(label: "Not Removable", removable: false))
      expect(result).not_to have_css("button.ui-chip__remove")
    end

    it "renders with combined options" do
      result = render_inline(described_class.new(
        label: "Complex Chip",
        variant: :primary,
        removable: true,
        href: "/complex"
      ))

      expect(result).to have_css("a.ui-chip.ui-chip--primary.ui-chip--removable.ui-chip--link[href='/complex']")
      expect(result).to have_css("span.ui-chip__label", text: "Complex Chip")
      expect(result).to have_css("button.ui-chip__remove", text: "×")
    end
  end

  describe "constants" do
    it "defines valid variants" do
      expected_variants = %i[primary secondary neutral creative accent]
      expect(described_class::VARIANTS).to eq(expected_variants)
    end
  end

  describe "private methods" do
    let(:component) { described_class.new(label: "Test") }

    describe "#element_tag" do
      it "returns :a when href is present" do
        component.instance_variable_set(:@href, "/path")
        expect(component.send(:element_tag)).to eq(:a)
      end

      it "returns :span when href is not present" do
        component.instance_variable_set(:@href, nil)
        expect(component.send(:element_tag)).to eq(:span)
      end

      it "returns :span when href is empty string" do
        component.instance_variable_set(:@href, "")
        expect(component.send(:element_tag)).to eq(:span)
      end
    end

    describe "#element_options" do
      it "returns class only when no href" do
        component.instance_variable_set(:@href, nil)
        options = component.send(:element_options)
        expect(options).to eq({ class: "ui-chip ui-chip--neutral" })
      end

      it "includes href when present" do
        component.instance_variable_set(:@href, "/path")
        options = component.send(:element_options)
        expect(options).to include(href: "/path")
      end
    end

    describe "#css_classes" do
      it "returns base classes for simple chip" do
        classes = component.send(:css_classes)
        expect(classes).to eq("ui-chip ui-chip--neutral")
      end

      it "includes removable class when removable" do
        component.instance_variable_set(:@removable, true)
        classes = component.send(:css_classes)
        expect(classes).to include("ui-chip--removable")
      end

      it "includes link class when href present" do
        component.instance_variable_set(:@href, "/path")
        classes = component.send(:css_classes)
        expect(classes).to include("ui-chip--link")
      end
    end

    describe "#validate_variant" do
      it "returns valid variants as symbols" do
        described_class::VARIANTS.each do |variant|
          result = component.send(:validate_variant, variant)
          expect(result).to eq(variant)
        end
      end

      it "returns :neutral for invalid variants" do
        result = component.send(:validate_variant, :invalid)
        expect(result).to eq(:neutral)
      end

      it "converts string variants to symbols" do
        result = component.send(:validate_variant, "primary")
        expect(result).to eq(:primary)
      end
    end
  end

  describe "all variants" do
    described_class::VARIANTS.each do |variant|
      it "renders #{variant} variant correctly" do
        result = render_inline(described_class.new(label: "Test", variant: variant))
        expect(result).to have_css("span.ui-chip--#{variant}", text: "Test")
      end
    end
  end
end
