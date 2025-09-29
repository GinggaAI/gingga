FactoryBot.define do
  factory :reel do
    user
    brand { create(:brand, user: user) }
    template { "only_avatars" }
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

    trait :only_avatars do
      template { "only_avatars" }
    end

    trait :avatar_and_video do
      template { "avatar_and_video" }
    end

    trait :narration_over_7_images do
      template { "narration_over_7_images" }
    end

    trait :one_to_three_videos do
      template { "one_to_three_videos" }
    end
  end
end
