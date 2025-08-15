FactoryBot.define do
  factory :reel do
    association :user
    mode { "scene_based" }
    status { "draft" }
    title { "Test Reel" }
    description { "Test description" }
    category { "educational" }
    format { "vertical" }
    story_content { "Test story content" }
    music_preference { "upbeat" }
    style_preference { "modern" }
    use_ai_avatar { false }
    additional_instructions { "Test instructions" }

    trait :narrative do
      mode { "narrative" }
    end

    trait :scene_based do
      mode { "scene_based" }
    end
  end
end
