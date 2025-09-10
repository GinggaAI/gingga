class ReelSceneBasedPresenter
  attr_reader :reel, :current_user

  def initialize(reel:, current_user:)
    @reel = reel
    @current_user = current_user
  end

  def page_title
    I18n.t("reels.scene_based.page_title")
  end

  def main_title
    I18n.t("reels.create_reel")
  end

  def main_description
    I18n.t("reels.description")
  end

  def scene_based_tab_active?
    true
  end

  def narrative_tab_active?
    false
  end

  def scene_based_tab_classes
    "flex-1 px-4 py-2 text-center rounded-md font-medium transition-colors tab-active"
  end

  def narrative_tab_classes
    "flex-1 px-4 py-2 text-center rounded-md font-medium transition-colors text-gray-600 hover:text-gray-900"
  end

  def has_errors?
    reel.errors.any?
  end

  def error_title
    I18n.t("reels.errors.fix_following")
  end

  def error_messages
    reel.errors.full_messages
  end

  def basic_info_title
    I18n.t("reels.basic_info.title")
  end

  def basic_info_description
    I18n.t("reels.basic_info.description")
  end

  def title_label
    I18n.t("reels.fields.title")
  end

  def title_placeholder
    I18n.t("reels.placeholders.title")
  end

  def description_label
    I18n.t("reels.fields.description")
  end

  def description_placeholder
    I18n.t("reels.placeholders.description")
  end

  def ai_avatar_title
    I18n.t("reels.ai_avatar.title")
  end

  def ai_avatar_description
    I18n.t("reels.ai_avatar.description")
  end

  def use_ai_avatars_label
    I18n.t("reels.ai_avatar.use_ai_avatars")
  end

  def use_ai_avatars_description
    I18n.t("reels.ai_avatar.enable_description")
  end

  def scene_breakdown_title
    I18n.t("reels.scene_breakdown.title")
  end

  def scene_breakdown_description
    I18n.t("reels.scene_breakdown.description")
  end

  def scene_count
    3
  end

  def scenes_label
    I18n.t("reels.scene_breakdown.scenes_count", count: scene_count)
  end

  def add_scene_label
    I18n.t("reels.scene_breakdown.add_scene")
  end

  def additional_instructions_title
    I18n.t("reels.additional_instructions.title")
  end

  def additional_instructions_description
    I18n.t("reels.additional_instructions.description")
  end

  def style_direction_label
    I18n.t("reels.additional_instructions.style_direction")
  end

  def style_direction_placeholder
    I18n.t("reels.placeholders.additional_instructions")
  end

  def submit_button_label
    I18n.t("reels.submit.scene_based")
  end

  def form_data_attributes
    {
      controller: "scene-list",
      scene_list_scene_count_value: scene_count
    }
  end

  def scene_data_for(index)
    reel.reel_scenes[index]&.attributes || {}
  end

  def avatars_for_select
    current_user.avatars.active.map do |avatar|
      [ avatar.name, avatar.avatar_id ]
    end
  end

  def has_avatars?
    current_user.avatars.active.exists?
  end

  def no_avatars_message
    I18n.t("reels.scene_based.no_avatars_message")
  end

  def voices_for_select
    current_user.voices.active.map do |voice|
      [ voice.name, voice.voice_id ]
    end
  end

  def has_voices?
    current_user.voices.active.exists?
  end

  def no_voices_message
    I18n.t("reels.scene_based.no_voices_message")
  end

  # JavaScript messages for internationalization
  def js_messages
    {
      max_scenes: I18n.t("reels.scene_based.max_scenes_message"),
      min_scenes: I18n.t("reels.scene_based.min_scenes_message"),
      remove_scene: I18n.t("reels.scene_based.remove_scene"),
      select_avatar: I18n.t("reels.scene_based.select_avatar"),
      select_voice: I18n.t("reels.scene_based.select_voice"),
      no_avatars: I18n.t("reels.scene_based.no_avatars_message"),
      avatar_help: I18n.t("reels.scene_based.scene_help_text.avatar"),
      voice_help: I18n.t("reels.scene_based.scene_help_text.voice"),
      script_help: I18n.t("reels.scene_based.scene_help_text.script"),
      script_placeholder: I18n.t("reels.scene_based.scene_script_placeholder")
    }
  end
end
