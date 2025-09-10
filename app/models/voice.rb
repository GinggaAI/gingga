class Voice < ApplicationRecord
  belongs_to :user

  validates :voice_id, presence: true
  validates :voice_id, uniqueness: { scope: :user_id }
  validates :name, presence: true
  validates :language, presence: true
  validates :gender, inclusion: { in: %w[male female unknown], allow_blank: true }

  scope :active, -> { where(active: true) }
  scope :by_language, ->(language) { where(language: language) }
  scope :by_gender, ->(gender) { where(gender: gender) }
  scope :supporting_pause, -> { where(support_pause: true) }
  scope :with_emotion_support, -> { where(emotion_support: true) }
  scope :for_interactive_avatar, -> { where(support_interactive_avatar: true) }

  def self.sync_for_user(user, voices_data)
    transaction do
      user.voices.update_all(active: false)

      voices_data.each do |voice_data|
        user.voices.find_or_create_by(voice_id: voice_data[:voice_id]) do |voice|
          voice.assign_attributes(
            language: voice_data[:language],
            gender: voice_data[:gender],
            name: voice_data[:name],
            preview_audio: voice_data[:preview_audio],
            support_pause: voice_data[:support_pause],
            emotion_support: voice_data[:emotion_support],
            support_interactive_avatar: voice_data[:support_interactive_avatar],
            support_locale: voice_data[:support_locale],
            active: true
          )
        end.tap do |voice|
          voice.update!(
            language: voice_data[:language],
            gender: voice_data[:gender],
            name: voice_data[:name],
            preview_audio: voice_data[:preview_audio],
            support_pause: voice_data[:support_pause],
            emotion_support: voice_data[:emotion_support],
            support_interactive_avatar: voice_data[:support_interactive_avatar],
            support_locale: voice_data[:support_locale],
            active: true
          )
        end
      end
    end
  end

  def display_name
    "#{name} (#{language}#{gender.present? ? ", #{gender}" : ''})"
  end

  def supports_feature?(feature)
    case feature.to_sym
    when :pause
      support_pause
    when :emotion
      emotion_support
    when :interactive_avatar
      support_interactive_avatar
    when :locale
      support_locale
    else
      false
    end
  end
end
