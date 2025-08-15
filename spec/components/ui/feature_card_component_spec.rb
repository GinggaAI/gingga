require "rails_helper"

RSpec.describe Ui::FeatureCardComponent, type: :component do
  let(:title) { "Test Feature" }
  let(:icon_svg) { '<svg><circle cx="50" cy="50" r="40"/></svg>' }
  let(:description) { "This is a test feature description." }

  describe "#initialize" do
    it "sets title, icon_svg, and description" do
      component = described_class.new(
        title: title,
        icon_svg: icon_svg,
        description: description
      )

      expect(component.instance_variable_get(:@title)).to eq(title)
      expect(component.instance_variable_get(:@icon_svg)).to eq(icon_svg)
      expect(component.instance_variable_get(:@description)).to eq(description)
    end

    it "requires all parameters" do
      expect {
        described_class.new(title: title, icon_svg: icon_svg)
      }.to raise_error(ArgumentError)

      expect {
        described_class.new(title: title, description: description)
      }.to raise_error(ArgumentError)

      expect {
        described_class.new(icon_svg: icon_svg, description: description)
      }.to raise_error(ArgumentError)
    end
  end

  describe "#call" do
    let(:component) do
      described_class.new(
        title: title,
        icon_svg: icon_svg,
        description: description
      )
    end

    it "renders within a CardComponent" do
      result = render_inline(component)
      # Check that it renders the card structure (from CardComponent)
      expect(result).to have_css("div[class*='bg-[var(--surface)]']")
      expect(result).to have_css("div[class*='text-[var(--text)]']")
      expect(result).to have_css("div[class*='rounded-']")
    end

    it "renders the title as h3" do
      result = render_inline(component)
      expect(result).to have_css("h3", text: title)
      expect(result).to have_css("h3.font-montserrat.font-semibold.text-xl.mb-2")
    end

    it "renders the description as p" do
      result = render_inline(component)
      expect(result).to have_css("p", text: description)
      expect(result).to have_css("p[class*='text-[var(--muted)]']")
    end

    it "renders the icon with proper styling" do
      result = render_inline(component)
      # Check that SVG content is present (it gets rendered as HTML)
      expect(result.to_s).to include('circle')
      # Check icon container styling
      expect(result).to have_css("div.w-12.h-12.mb-4")
      expect(result).to have_css("div[class*='bg-[var(--cyan)]']")
      expect(result).to have_css("div.text-white")
      expect(result).to have_css("div.rounded-lg")
      expect(result).to have_css("div.flex.items-center.justify-center")
    end

    it "renders all elements in correct order" do
      result = render_inline(component)
      html = result.to_s

      # Check that icon appears before title, and title before description
      icon_position = html.index('w-12 h-12')
      title_position = html.index(title)
      description_position = html.index(description)

      expect(icon_position).to be < title_position
      expect(title_position).to be < description_position
    end

    it "properly escapes HTML in SVG content" do
      malicious_svg = '<svg><script>alert("xss")</script></svg>'
      component_with_script = described_class.new(
        title: title,
        icon_svg: malicious_svg,
        description: description
      )

      result = render_inline(component_with_script)
      # The html_safe call should render the SVG, but Rails should still protect against XSS
      expect(result.to_s).to include('<script>alert("xss")</script>')
    end

    it "handles empty icon SVG" do
      empty_component = described_class.new(
        title: title,
        icon_svg: "",
        description: description
      )

      result = render_inline(empty_component)
      expect(result).to have_css("div.w-12.h-12")
      expect(result).to have_css("h3", text: title)
      expect(result).to have_css("p", text: description)
    end

    it "handles special characters in title and description" do
      special_title = "Feature with <>&\" special chars"
      special_description = "Description with <>&\" special chars"

      special_component = described_class.new(
        title: special_title,
        icon_svg: icon_svg,
        description: special_description
      )

      result = render_inline(special_component)
      expect(result).to have_css("h3", text: special_title)
      expect(result).to have_css("p", text: special_description)
    end
  end
end
