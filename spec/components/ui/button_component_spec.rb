require "rails_helper"

RSpec.describe Ui::ButtonComponent, type: :component do
  it "renders a primary button with label" do
    render_inline(described_class.new(label: "Click me"))
    expect(rendered_component).to have_css(".ui-button.ui-button--primary", text: "Click me")
  end

  it "renders as a link when href is provided" do
    render_inline(described_class.new(label: "Go", href: "/"))
    expect(rendered_component).to have_css("a.ui-button", text: "Go")
  end
end

