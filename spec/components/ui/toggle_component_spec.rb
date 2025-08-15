require "rails_helper"

RSpec.describe Ui::ToggleComponent, type: :component do
  it "renders a toggle with label" do
    result = render_inline(described_class.new(
      name: "test_toggle",
      label: "Enable Feature"
    ))

    expect(result).to have_css(".ui-toggle")
    expect(result).to have_css("input[type='checkbox'][name='test_toggle']")
    expect(result).to have_css(".ui-toggle__text", text: "Enable Feature")
  end

  it "renders checked toggle when specified" do
    result = render_inline(described_class.new(
      name: "test_toggle",
      label: "Enable Feature",
      checked: true
    ))

    expect(result).to have_css("input[checked]")
  end

  it "renders disabled toggle when specified" do
    result = render_inline(described_class.new(
      name: "test_toggle",
      label: "Enable Feature",
      disabled: true
    ))

    expect(result).to have_css("input[disabled]")
  end

  it "renders description when provided" do
    result = render_inline(described_class.new(
      name: "test_toggle",
      label: "Enable Feature",
      description: "This enables the awesome feature"
    ))

    expect(result).to have_css(".ui-toggle__description", text: "This enables the awesome feature")
  end

  it "generates proper IDs for accessibility" do
    result = render_inline(described_class.new(
      name: "ai_avatar",
      label: "AI Avatar",
      description: "Enable AI avatars"
    ))

    expect(result).to have_css("input#toggle_ai_avatar")
    expect(result).to have_css("label[for='toggle_ai_avatar']")
    expect(result).to have_css("span#toggle_ai_avatar_description")
    expect(result).to have_css("input[aria-describedby='toggle_ai_avatar_description']")
  end
end
