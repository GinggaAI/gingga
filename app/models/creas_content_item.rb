class CreasContentItem < ApplicationRecord
  belongs_to :creas_strategy_plan
  belongs_to :user
  belongs_to :brand

  validates :content_id, presence: true, uniqueness: true
  validates :content_name, :status, :creation_date, :content_type,
            :platform, :week, :pilar, :template, :video_source, presence: true

  # Ensure content uniqueness within the same month for the same brand
  validate :content_uniqueness_within_month
  validates :publish_date, presence: true, unless: -> { status == "draft" }

  validates :status, inclusion: {
    in: %w[draft in_progress in_production ready_for_review approved],
    message: "%{value} is not a valid status"
  }

  validates :template, inclusion: {
    in: %w[only_avatars avatar_and_video narration_over_7_images remix one_to_three_videos],
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

  validates :day_of_the_week, inclusion: {
    in: %w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday],
    message: "%{value} is not a valid day of the week"
  }, allow_blank: true

  validates :hashtags, format: {
    with: /\A(?:#\w+(?:\s+#\w+)*|\s*)\z/m,
    message: "must be space-separated hashtags like '#tag1 #tag2 #tag3'"
  }, allow_blank: true

  validate :no_newlines_in_hashtags

  scope :by_week, ->(week) { where(week: week) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_day_of_week, ->(day) { where(day_of_the_week: day) }
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

  def hook
    meta.dig("hook")
  end

  def cta
    meta.dig("cta")
  end

  private

  def no_newlines_in_hashtags
    return if hashtags.blank?

    if hashtags.include?("\n") || hashtags.include?("\r")
      errors.add(:hashtags, "cannot contain newlines")
    end
  end

  def content_uniqueness_within_month
    return unless brand_id.present?

    # Check for identical content names across ALL months for the same brand
    similar_content = CreasContentItem
      .where(brand_id: brand_id)
      .where.not(id: id) # Exclude current record
      .where(content_name: content_name)

    if similar_content.exists?
      existing_months = similar_content.joins(:creas_strategy_plan).pluck("creas_strategy_plans.month").uniq.sort
      current_month = creas_strategy_plan&.month

      if existing_months.include?(current_month)
        errors.add(:content_name, "already exists for this brand in #{current_month}. Content names must be unique.")
      else
        errors.add(:content_name, "already exists for this brand (previously used in #{existing_months.join(', ')}). Content names must be unique across all months.")
      end
    end

    # Check for very similar post descriptions (if present and substantial)
    if post_description.present? && post_description.length > 50
      # Use similarity check for descriptions - exact matches and very similar ones
      similar_descriptions = CreasContentItem
        .where(brand_id: brand_id)
        .where.not(id: id)
        .where("LENGTH(post_description) > 50")

      similar_descriptions.find_each do |item|
        next unless item.post_description.present?

        similarity = calculate_text_similarity(post_description, item.post_description)
        if similarity > 0.8 # 80% similarity threshold
          existing_month = item.creas_strategy_plan&.month
          errors.add(:post_description, "is very similar to existing content from #{existing_month}. Content must be unique.")
          break
        end
      end
    end

    # Check for very similar text_base content (if present and substantial)
    if text_base.present? && text_base.length > 100
      similar_text_base = CreasContentItem
        .where(brand_id: brand_id)
        .where.not(id: id)
        .where("LENGTH(text_base) > 100")

      similar_text_base.find_each do |item|
        next unless item.text_base.present?

        similarity = calculate_text_similarity(text_base, item.text_base)
        if similarity > 0.75 # 75% similarity threshold for text base
          existing_month = item.creas_strategy_plan&.month
          errors.add(:text_base, "is very similar to existing content from #{existing_month}. Content must be unique.")
          break
        end
      end
    end
  end

  def calculate_text_similarity(text1, text2)
    return 0.0 if text1.blank? || text2.blank?

    # Simple similarity based on common words (for performance)
    # Normalize texts: lowercase, remove punctuation, split into words
    words1 = text1.downcase.gsub(/[^\w\s]/, "").split
    words2 = text2.downcase.gsub(/[^\w\s]/, "").split

    return 1.0 if words1 == words2 # Exact match
    return 0.0 if words1.empty? || words2.empty?

    # Calculate Jaccard similarity (intersection over union)
    intersection = (words1 & words2).size.to_f
    union = (words1 | words2).size.to_f

    intersection / union
  end
end
