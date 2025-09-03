class Reel < ApplicationRecord
  belongs_to :user
  has_many :reel_scenes, dependent: :destroy

  accepts_nested_attributes_for :reel_scenes, allow_destroy: true

  validates :template, presence: true, inclusion: {
    in: %w[solo_avatars avatar_and_video narration_over_7_images one_to_three_videos],
    message: "%{value} is not a valid template"
  }
  validates :status, inclusion: { in: %w[draft processing completed failed] }

  validate :must_have_exactly_three_scenes, if: -> { template.in?(%w[solo_avatars avatar_and_video]) }
  validate :all_scenes_must_be_complete, if: -> { requires_scenes? }

  scope :by_template, ->(template) { where(template: template) }
  scope :by_status, ->(status) { where(status: status) }

  def ready_for_generation?
    case template
    when "solo_avatars", "avatar_and_video"
      reel_scenes.count == 3 && reel_scenes.all?(&:complete?)
    when "narration_over_7_images"
      # Will need narrative content fields - placeholder for now
      true
    when "one_to_three_videos"
      # Will need video content fields - placeholder for now
      true
    else
      false
    end
  end

  def requires_scenes?
    template.in?(%w[solo_avatars avatar_and_video])
  end

  private

  def must_have_exactly_three_scenes
    return unless persisted? # Skip validation for new records

    errors.add(:reel_scenes, "must have exactly 3 scenes for #{template} template") if reel_scenes.count != 3
  end

  def all_scenes_must_be_complete
    return unless persisted?

    incomplete_scenes = reel_scenes.reject(&:complete?)
    if incomplete_scenes.any?
      scene_numbers = incomplete_scenes.map(&:scene_number).sort.join(", ")
      errors.add(:reel_scenes, "scenes #{scene_numbers} are incomplete")
    end
  end
end
