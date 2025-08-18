require "rails_helper"

RSpec.describe Ui::ToastComponent, type: :component do
  it "renders toast with message" do
    result = render_inline(described_class.new(message: "Success message"))

    expect(result).to have_css(".ui-toast", text: "Success message")
    expect(result).to have_css("[role='alert']")
  end

  it "renders with correct variant classes" do
    %i[success warning error info].each do |variant|
      result = render_inline(described_class.new(
        message: "Test message",
        variant: variant
      ))

      expect(result).to have_css(".ui-toast--#{variant}")
    end
  end

  it "renders dismiss button when dismissible" do
    result = render_inline(described_class.new(
      message: "Test message",
      dismissible: true
    ))

    expect(result).to have_css(".ui-toast__dismiss")
    expect(result).to have_css(".ui-toast--dismissible")
  end

  it "does not render dismiss button when not dismissible" do
    result = render_inline(described_class.new(
      message: "Test message",
      dismissible: false
    ))

    expect(result).not_to have_css(".ui-toast__dismiss")
    expect(result).not_to have_css(".ui-toast--dismissible")
  end

  it "renders auto-dismiss class when enabled" do
    result = render_inline(described_class.new(
      message: "Test message",
      auto_dismiss: true
    ))

    expect(result).to have_css(".ui-toast--auto-dismiss")
  end

  it "includes proper data attributes for Stimulus controller" do
    result = render_inline(described_class.new(
      message: "Test message",
      auto_dismiss: true
    ))

    expect(result).to have_css("[data-controller='toast']")
    expect(result).to have_css("[data-toast-auto-dismiss-value='true']")
    expect(result).to have_css("[data-toast-duration-value='5000']")
  end

  it "renders appropriate icons for variants" do
    {
      success: "✓",
      warning: "⚠",
      error: "✕",
      info: "ℹ"
    }.each do |variant, icon|
      result = render_inline(described_class.new(
        message: "Test",
        variant: variant
      ))

      expect(result).to have_css(".ui-toast__icon", text: icon)
    end
  end
end
