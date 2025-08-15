module Ui
  class SceneFieldsComponent < ViewComponent::Base
    attr_reader :form, :scene_number, :scene_data

    def initialize(form:, scene_number:, scene_data: {})
      @form = form
      @scene_number = scene_number
      @scene_data = scene_data || {}
    end

    def call
      content_tag(:div, class: "ui-scene-fields", data: { scene_number: scene_number }) do
        concat(render_header)
        concat(render_fields)
      end
    end

    private

    def render_header
      content_tag(:div, class: "ui-scene-fields__header") do
        concat(content_tag(:h4, "Scene #{scene_number}", class: "ui-scene-fields__title"))
        concat(render_remove_button) if scene_number > 1
      end
    end

    def render_fields
      content_tag(:div, class: "ui-scene-fields__content") do
        form.fields_for "scenes", index: scene_number do |scene_form|
          concat(render_hidden_scene_number(scene_form))
          concat(render_avatar_field(scene_form))
          concat(render_voice_field(scene_form))
          concat(render_script_field(scene_form))
        end
      end
    end

    def render_hidden_scene_number(scene_form)
      scene_form.hidden_field :scene_number, value: scene_number
    end

    def render_avatar_field(scene_form)
      content_tag(:div, class: "ui-scene-fields__field") do
        concat(scene_form.label :avatar_id, "AI Avatar", class: "ui-scene-fields__label")
        concat(scene_form.select :avatar_id,
          options_for_select([
            [ "Select Avatar", "" ],
            [ "Professional Male", "avatar_001" ],
            [ "Professional Female", "avatar_002" ],
            [ "Casual Male", "avatar_003" ],
            [ "Casual Female", "avatar_004" ]
          ], scene_data[:avatar_id]),
          {},
          {
            class: "ui-scene-fields__select",
            "aria-describedby": "avatar_help_#{scene_number}"
          }
        )
        concat(content_tag(:small, "Choose the AI avatar for this scene",
          id: "avatar_help_#{scene_number}",
          class: "ui-scene-fields__help"
        ))
      end
    end

    def render_voice_field(scene_form)
      content_tag(:div, class: "ui-scene-fields__field") do
        concat(scene_form.label :voice_id, "Voice", class: "ui-scene-fields__label")
        concat(scene_form.select :voice_id,
          options_for_select([
            [ "Select Voice", "" ],
            [ "Clear Male Voice", "voice_001" ],
            [ "Clear Female Voice", "voice_002" ],
            [ "Friendly Male Voice", "voice_003" ],
            [ "Friendly Female Voice", "voice_004" ]
          ], scene_data[:voice_id]),
          {},
          {
            class: "ui-scene-fields__select",
            "aria-describedby": "voice_help_#{scene_number}"
          }
        )
        concat(content_tag(:small, "Choose the voice for this scene",
          id: "voice_help_#{scene_number}",
          class: "ui-scene-fields__help"
        ))
      end
    end

    def render_script_field(scene_form)
      content_tag(:div, class: "ui-scene-fields__field") do
        concat(scene_form.label :script, "Script", class: "ui-scene-fields__label")
        concat(scene_form.text_area :script,
          value: scene_data[:script],
          placeholder: "Enter the script for Scene #{scene_number}. What should the avatar say in this scene?",
          class: "ui-scene-fields__textarea",
          rows: 4,
          maxlength: 500,
          "aria-describedby": "script_help_#{scene_number}"
        )
        concat(content_tag(:div, class: "ui-scene-fields__field-footer") do
          concat(content_tag(:small, "Keep it under 500 characters for best results",
            id: "script_help_#{scene_number}",
            class: "ui-scene-fields__help"
          ))
          concat(content_tag(:span, "0/500",
            class: "ui-scene-fields__char-count",
            data: { scene_character_counter_target: "counter" }
          ))
        end)
      end
    end

    def render_remove_button
      content_tag(:button,
        type: "button",
        class: "ui-scene-fields__remove",
        data: { action: "click->scene-list#removeScene" },
        "aria-label": "Remove Scene #{scene_number}"
      ) do
        "Remove Scene"
      end
    end
  end
end
