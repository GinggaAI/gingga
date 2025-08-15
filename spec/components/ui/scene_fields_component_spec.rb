require "rails_helper"

RSpec.describe Ui::SceneFieldsComponent, type: :component do
  let(:mock_form) do
    double("form").tap do |form|
      allow(form).to receive(:fields_for).and_yield(mock_scene_form)
    end
  end

  let(:mock_scene_form) do
    double("scene_form").tap do |scene_form|
      allow(scene_form).to receive(:hidden_field).and_return("")
      allow(scene_form).to receive(:label).and_return("<label>Test Label</label>".html_safe)
      allow(scene_form).to receive(:select).and_return("<select></select>".html_safe)
      allow(scene_form).to receive(:text_area).and_return("<textarea></textarea>".html_safe)
    end
  end

  it "renders scene fields with scene number" do
    result = render_inline(described_class.new(
      form: mock_form,
      scene_number: 1
    ))

    expect(result).to have_css(".ui-scene-fields[data-scene-number='1']")
    expect(result).to have_css(".ui-scene-fields__title", text: "Scene 1")
  end

  it "renders remove button for scenes after the first" do
    result = render_inline(described_class.new(
      form: mock_form,
      scene_number: 2
    ))

    expect(result).to have_css(".ui-scene-fields__remove", text: "Remove Scene")
  end

  it "does not render remove button for first scene" do
    result = render_inline(described_class.new(
      form: mock_form,
      scene_number: 1
    ))

    expect(result).not_to have_css(".ui-scene-fields__remove")
  end

  it "renders with provided scene data" do
    result = render_inline(described_class.new(
      form: mock_form,
      scene_number: 1,
      scene_data: { avatar_id: "avatar_001", script: "Test script" }
    ))

    expect(result).to have_css(".ui-scene-fields")
  end
end
