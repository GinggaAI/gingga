FactoryBot.define do
  factory :voice do
    association :user
    sequence(:voice_id) { |n| "voice_#{n}_#{SecureRandom.hex(4)}" }
    language { "English" }
    gender { "unknown" }
    sequence(:name) { |n| "voice_#{n}" }
    preview_audio { nil }
    support_pause { true }
    emotion_support { false }
    support_interactive_avatar { false }
    support_locale { false }
    active { true }

    trait :female do
      gender { "female" }
      sequence(:name) { |n| "female_voice_#{n}" }
    end

    trait :male do
      gender { "male" }
      sequence(:name) { |n| "male_voice_#{n}" }
    end

    trait :spanish do
      language { "Spanish" }
      sequence(:name) { |n| "spanish_voice_#{n}" }
    end

    trait :with_emotion_support do
      emotion_support { true }
    end

    trait :interactive_avatar_compatible do
      support_interactive_avatar { true }
    end

    trait :with_preview_audio do
      preview_audio { "https://example.com/preview.mp3" }
    end

    trait :inactive do
      active { false }
    end

    trait :full_featured do
      support_pause { true }
      emotion_support { true }
      support_interactive_avatar { true }
      support_locale { true }
      preview_audio { "https://example.com/preview.mp3" }
    end
  end
end
