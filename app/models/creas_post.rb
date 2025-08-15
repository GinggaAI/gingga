class CreasPost < ApplicationRecord
  belongs_to :user
  belongs_to :creas_strategy_plan
  validates :content_name, :status, :creation_date, :publish_date, :content_type,
           :platform, :pilar, :template, :video_source, :post_description,
           :text_base, :hashtags, presence: true

  before_save :set_defaults

  private

  def set_defaults
    self.content_type = "Video" if content_type.blank?
    self.platform = "Instagram Reels" if platform.blank?
    self.aspect_ratio = "9:16" if aspect_ratio.blank?
  end
end
