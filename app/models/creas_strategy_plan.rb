class CreasStrategyPlan < ApplicationRecord
  belongs_to :user
  belongs_to :brand
  has_many :creas_posts, dependent: :destroy
  has_many :creas_content_items, dependent: :destroy

  attribute :status, :string, default: "pending"

  enum :status, {
    pending: "pending",
    processing: "processing",
    completed: "completed",
    failed: "failed"
  }

  validates :month, presence: true
  validates :objective_of_the_month, :frequency_per_week, presence: true, if: :completed?
  validates :selected_templates, presence: true, if: :completed?
  validate :validate_selected_templates

  scope :recent, -> { order(created_at: :desc) }

  ALLOWED_TEMPLATES = %w[
    only_avatars
    avatar_and_video
    narration_over_7_images
    remix
    one_to_three_videos
  ].freeze

  def content_stats
    creas_content_items.group(:status, :template, :video_source).count
  end

  def current_week_items
    current_week = calculate_current_week
    return creas_content_items.none if current_week.nil?

    creas_content_items.by_week(current_week)
  end

  private

  def validate_selected_templates
    return if selected_templates.nil?

    unless selected_templates.is_a?(Array)
      errors.add(:selected_templates, "must be an array")
      return
    end

    if selected_templates.empty?
      errors.add(:selected_templates, "cannot be empty when provided")
      return
    end

    invalid_templates = selected_templates - ALLOWED_TEMPLATES
    if invalid_templates.any?
      errors.add(:selected_templates, "contains invalid templates: #{invalid_templates.join(', ')}")
    end
  end

  def calculate_current_week
    return nil unless month.present?

    begin
      month_start = Date.parse("#{month}-01")
      current_date = Date.current

      return nil if current_date < month_start || current_date > month_start.end_of_month

      ((current_date - month_start).to_i / 7) + 1
    rescue Date::Error
      nil
    end
  end
end
