module Ui
  class SceneFieldsComponentPreview < ViewComponent::Preview
    def default
      # Create a mock form object for the preview
      reel = OpenStruct.new(
        reel_scenes: []
      )

      # Create a mock form builder
      form_builder = OpenStruct.new
      form_builder.define_singleton_method(:fields_for) do |name, options = {}, &block|
        mock_scene_form = OpenStruct.new
        mock_scene_form.define_singleton_method(:hidden_field) { |field, options = {}| "" }
        mock_scene_form.define_singleton_method(:label) { |field, text, options = {}| "<label>#{text}</label>" }
        mock_scene_form.define_singleton_method(:select) { |field, choices, options = {}, html_options = {}| "<select></select>" }
        mock_scene_form.define_singleton_method(:text_area) { |field, options = {}| "<textarea></textarea>" }

        block.call(mock_scene_form) if block_given?
      end

      render(Ui::SceneFieldsComponent.new(
        form: form_builder,
        scene_number: 1
      ))
    end

    def with_data
      # Create a mock form object for the preview
      reel = OpenStruct.new(
        reel_scenes: []
      )

      # Create a mock form builder
      form_builder = OpenStruct.new
      form_builder.define_singleton_method(:fields_for) do |name, options = {}, &block|
        mock_scene_form = OpenStruct.new
        mock_scene_form.define_singleton_method(:hidden_field) { |field, options = {}| "" }
        mock_scene_form.define_singleton_method(:label) { |field, text, options = {}| "<label>#{text}</label>" }
        mock_scene_form.define_singleton_method(:select) { |field, choices, options = {}, html_options = {}| "<select></select>" }
        mock_scene_form.define_singleton_method(:text_area) { |field, options = {}| "<textarea></textarea>" }

        block.call(mock_scene_form) if block_given?
      end

      render(Ui::SceneFieldsComponent.new(
        form: form_builder,
        scene_number: 2,
        scene_data: {
          avatar_id: "avatar_001",
          voice_id: "voice_002",
          script: "Welcome to our brand story. This is an example script that shows how the scene component works."
        }
      ))
    end

    def removable_scene
      # Create a mock form object for the preview
      reel = OpenStruct.new(
        reel_scenes: []
      )

      # Create a mock form builder
      form_builder = OpenStruct.new
      form_builder.define_singleton_method(:fields_for) do |name, options = {}, &block|
        mock_scene_form = OpenStruct.new
        mock_scene_form.define_singleton_method(:hidden_field) { |field, options = {}| "" }
        mock_scene_form.define_singleton_method(:label) { |field, text, options = {}| "<label>#{text}</label>" }
        mock_scene_form.define_singleton_method(:select) { |field, choices, options = {}, html_options = {}| "<select></select>" }
        mock_scene_form.define_singleton_method(:text_area) { |field, options = {}| "<textarea></textarea>" }

        block.call(mock_scene_form) if block_given?
      end

      render(Ui::SceneFieldsComponent.new(
        form: form_builder,
        scene_number: 3
      ))
    end
  end
end
