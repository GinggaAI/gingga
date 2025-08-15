class Reel < ApplicationRecord
  belongs_to :user
  has_many :reel_scenes, dependent: :destroy

  accepts_nested_attributes_for :reel_scenes, allow_destroy: true

  validates :mode, presence: true, inclusion: { in: %w[scene_based narrative] }
  validates :status, inclusion: { in: %w[draft processing completed failed] }

  validate :must_have_exactly_three_scenes, if: -> { mode == "scene_based" }
  validate :all_scenes_must_be_complete, if: -> { mode == "scene_based" }

  scope :scene_based, -> { where(mode: "scene_based") }
  scope :by_status, ->(status) { where(status: status) }

  def ready_for_generation?
    mode == "scene_based" &&
    reel_scenes.count == 3 &&
    reel_scenes.all?(&:complete?)
  end

  private

  def must_have_exactly_three_scenes
    return unless persisted? # Skip validation for new records

    errors.add(:reel_scenes, "must have exactly 3 scenes for scene_based mode") if reel_scenes.count != 3
  end

  def all_scenes_must_be_complete
    return unless persisted?

    incomplete_scenes = reel_scenes.reject(&:complete?)
    if incomplete_scenes.any?
      errors.add(:reel_scenes, "scenes #{incomplete_scenes.map(&:scene_number).join(', ')} are incomplete")
    end
  end
end
