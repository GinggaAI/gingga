class Brand < ApplicationRecord
  belongs_to :user
  has_many :audiences, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :brand_channels, dependent: :destroy
  has_many :creas_strategy_plans, dependent: :destroy

  validates :name, :slug, :industry, :voice, presence: true
  validates :slug, uniqueness: { scope: :user_id }

  # Virtual attributes for form handling
  attr_accessor :tone_no_go_list, :banned_words_list, :claims_rules_text
  attr_accessor :kling_enabled, :stock_enabled, :budget_enabled, :editing_enabled, :ai_avatars_enabled, :podcast_clips_enabled

  # Callbacks to handle JSON field conversions
  before_save :build_guardrails_json, :build_resources_json
  after_find :populate_virtual_attributes

  private

  def build_guardrails_json
    self.guardrails = {
      "tone_no_go" => tone_no_go_list&.split(",")&.map(&:strip)&.reject(&:blank?) || [],
      "banned_words" => banned_words_list&.split(",")&.map(&:strip)&.reject(&:blank?) || [],
      "claims_rules" => claims_rules_text || ""
    }
  end

  def build_resources_json
    self.resources = {
      "kling" => kling_enabled == "1" || kling_enabled == true,
      "stock" => stock_enabled == "1" || stock_enabled == true,
      "budget" => budget_enabled == "1" || budget_enabled == true,
      "editing" => editing_enabled == "1" || editing_enabled == true,
      "ai_avatars" => ai_avatars_enabled == "1" || ai_avatars_enabled == true,
      "podcast_clips" => podcast_clips_enabled == "1" || podcast_clips_enabled == true
    }
  end

  def populate_virtual_attributes
    return unless persisted? # Only populate for persisted records

    if guardrails.present?
      self.tone_no_go_list = array_to_string(guardrails["tone_no_go"])
      self.banned_words_list = array_to_string(guardrails["banned_words"])
      self.claims_rules_text = guardrails["claims_rules"]
    end

    if resources.present?
      self.kling_enabled = resources["kling"]
      self.stock_enabled = resources["stock"]
      self.budget_enabled = resources["budget"]
      self.editing_enabled = resources["editing"]
      self.ai_avatars_enabled = resources["ai_avatars"]
      self.podcast_clips_enabled = resources["podcast_clips"]
    end
  end

  private

  def array_to_string(value)
    return nil if value.blank?
    value.is_a?(Array) ? value.join(", ") : value
  end
end
