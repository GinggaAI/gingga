class CreasContentItem < ApplicationRecord
  belongs_to :creas_strategy_plan
  belongs_to :user
  belongs_to :brand

  validates :content_id, presence: true, uniqueness: true
  validates :content_name, :status, :creation_date, :publish_date, :content_type,
            :platform, :week, :pilar, :template, :video_source, presence: true

  validates :status, inclusion: {
    in: %w[in_production ready_for_review approved],
    message: "%{value} is not a valid status"
  }

  validates :template, inclusion: {
    in: %w[solo_avatars avatar_and_video narration_over_7_images remix one_to_three_videos],
    message: "%{value} is not a valid template"
  }

  validates :video_source, inclusion: {
    in: %w[none external kling],
    message: "%{value} is not a valid video source"
  }

  validates :pilar, inclusion: {
    in: %w[C R E A S],
    message: "%{value} is not a valid pilar"
  }

  validates :hashtags, format: {
    with: /\A(?:#\w+(?:\s+#\w+)*|\s*)\z/m,
    message: "must be space-separated hashtags like '#tag1 #tag2 #tag3'"
  }, allow_blank: true

  validate :no_newlines_in_hashtags

  scope :by_week, ->(week) { where(week: week) }
  scope :by_status, ->(status) { where(status: status) }
  scope :ready_to_publish, -> { where(status: %w[ready_for_review approved]) }
  scope :for_month, ->(month) {
    joins(:creas_strategy_plan).where(creas_strategy_plans: { month: month })
  }

  def formatted_hashtags
    return [] if hashtags.blank?
    hashtags.split(/\s+/).reject(&:blank?)
  end

  def scenes
    shotplan.dig("scenes") || []
  end

  def beats
    shotplan.dig("beats") || []
  end

  def external_videos
    assets.dig("external_video_url").present? ? [ assets["external_video_url"] ] : assets.dig("video_urls") || []
  end

  def kpi_focus
    read_attribute(:kpi_focus) || meta.dig("kpi_focus")
  end

  def success_criteria
    read_attribute(:success_criteria) || meta.dig("success_criteria")
  end

  def compliance_check
    read_attribute(:compliance_check) || meta.dig("compliance_check") || "ok"
  end

  private

  def no_newlines_in_hashtags
    return if hashtags.blank?

    if hashtags.include?("\n") || hashtags.include?("\r")
      errors.add(:hashtags, "cannot contain newlines")
    end
  end
end
