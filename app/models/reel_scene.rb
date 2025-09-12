class ReelScene < ApplicationRecord
  belongs_to :reel, counter_cache: true

  validates :avatar_id, presence: true, unless: :reel_is_draft?
  validates :voice_id, presence: true, unless: :reel_is_draft?
  validates :script, presence: true, length: { minimum: 1, maximum: 5000 }, unless: :reel_is_draft?
  validates :scene_number, presence: true,
                          inclusion: { in: 1..3 },
                          uniqueness: { scope: :reel_id }
  validates :video_type, presence: true, inclusion: { in: %w[avatar kling] }, unless: :reel_is_draft?

  scope :ordered, -> { order(:scene_number) }
  scope :by_scene_number, ->(number) { where(scene_number: number) }

  def complete?
    return false unless voice_id.present? && script.present? && video_type.present?

    case video_type
    when "avatar"
      avatar_id.present?
    when "kling"
      # Kling videos don't require avatar_id
      true
    else
      # Default to requiring avatar_id for unknown types
      avatar_id.present?
    end
  end

  def to_heygen_payload
    {
      avatar_id: avatar_id,
      voice_id: voice_id,
      script: script,
      video_type: video_type
    }
  end

  private

  def reel_is_draft?
    reel&.status == "draft"
  end
end
