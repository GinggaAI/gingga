require "rails_helper"

RSpec.describe Ui::FormSectionComponent, type: :component do
  it "renders form section with title" do
    result = render_inline(described_class.new(title: "Brand Identity")) do
      "Form content"
    end

    expect(result).to have_css(".ui-form-section")
    expect(result).to have_css(".ui-form-section__title", text: "Brand Identity")
    expect(result).to have_css(".ui-form-section__content", text: "Form content")
  end

  it "renders description when provided" do
    result = render_inline(described_class.new(
      title: "Brand Identity",
      description: "Core information about your brand"
    )) do
      "Form content"
    end

    expect(result).to have_css(".ui-form-section__description", text: "Core information about your brand")
  end

  it "does not render description when not provided" do
    result = render_inline(described_class.new(title: "Brand Identity")) do
      "Form content"
    end

    expect(result).not_to have_css(".ui-form-section__description")
  end

  it "renders with proper structure" do
    result = render_inline(described_class.new(title: "Test Section")) do
      "Content"
    end

    expect(result).to have_css("section.ui-form-section")
    expect(result).to have_css("header.ui-form-section__header")
    expect(result).to have_css("h3.ui-form-section__title")
    expect(result).to have_css("div.ui-form-section__content")
  end
end
