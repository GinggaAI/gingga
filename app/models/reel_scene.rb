class ReelScene < ApplicationRecord
  belongs_to :reel

  validates :avatar_id, presence: true
  validates :voice_id, presence: true
  validates :script, presence: true, length: { minimum: 1, maximum: 5000 }
  validates :scene_number, presence: true,
                          inclusion: { in: 1..3 },
                          uniqueness: { scope: :reel_id }
  validates :video_type, presence: true, inclusion: { in: %w[avatar kling] }

  scope :ordered, -> { order(:scene_number) }
  scope :by_scene_number, ->(number) { where(scene_number: number) }

  def complete?
    avatar_id.present? && voice_id.present? && script.present? && video_type.present?
  end

  def to_heygen_payload
    {
      avatar_id: avatar_id,
      voice_id: voice_id,
      script: script,
      video_type: video_type
    }
  end
end
