class CreasStrategyPlan < ApplicationRecord
  belongs_to :user
  belongs_to :brand
  has_many :creas_posts, dependent: :destroy
  has_many :creas_content_items, dependent: :destroy

  validates :month, :objective_of_the_month, :frequency_per_week, presence: true

  def content_stats
    creas_content_items.group(:status, :template, :video_source).count
  end

  def current_week_items
    current_week = calculate_current_week
    return creas_content_items.none if current_week.nil?

    creas_content_items.by_week(current_week)
  end

  private

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
