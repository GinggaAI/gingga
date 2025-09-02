class ReelNarrativePresenter
  attr_reader :reel, :current_user

  def initialize(reel:, current_user:)
    @reel = reel
    @current_user = current_user
  end

  def page_title
    I18n.t('reels.narrative.page_title')
  end

  def main_title
    I18n.t('reels.create_reel')
  end

  def main_description
    I18n.t('reels.description')
  end

  def scene_based_tab_active?
    false
  end

  def narrative_tab_active?
    true
  end

  def scene_based_tab_classes
    "flex-1 px-4 py-2 text-center rounded-md font-medium transition-colors text-gray-600 hover:text-gray-900"
  end

  def narrative_tab_classes
    "flex-1 px-4 py-2 text-center rounded-md font-medium transition-colors text-white"
  end

  def narrative_tab_style
    "background-color: #FFC857"
  end

  def has_errors?
    reel.errors.any?
  end

  def error_title
    I18n.t('reels.errors.fix_following')
  end

  def error_messages
    reel.errors.full_messages
  end

  def basic_info_title
    I18n.t('reels.basic_info.title')
  end

  def basic_info_description
    I18n.t('reels.basic_info.description')
  end

  def title_label
    I18n.t('reels.fields.title')
  end

  def title_placeholder
    I18n.t('reels.placeholders.title')
  end

  def description_label
    I18n.t('reels.fields.description')
  end

  def description_placeholder
    I18n.t('reels.placeholders.description')
  end

  def narrative_content_title
    I18n.t('reels.narrative.content_title')
  end

  def narrative_content_description
    I18n.t('reels.narrative.content_description')
  end

  def narration_text_label
    I18n.t('reels.narrative.narration_text')
  end

  def narration_text_placeholder
    I18n.t('reels.placeholders.narration_text')
  end

  def image_themes_title
    I18n.t('reels.narrative.image_themes_title')
  end

  def image_themes_description
    I18n.t('reels.narrative.image_themes_description')
  end

  def image_themes_label
    I18n.t('reels.narrative.image_themes')
  end

  def image_themes_placeholder
    I18n.t('reels.placeholders.image_themes')
  end

  def additional_instructions_title
    I18n.t('reels.additional_instructions.title')
  end

  def additional_instructions_description
    I18n.t('reels.additional_instructions.description')
  end

  def style_direction_label
    I18n.t('reels.additional_instructions.style_direction')
  end

  def style_direction_placeholder
    I18n.t('reels.placeholders.additional_instructions')
  end

  def submit_button_label
    I18n.t('reels.submit.narrative')
  end
end