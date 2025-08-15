FactoryBot.define do
  factory :brand do
    association :user
    name { "Test Brand" }
    slug { "test-brand" }
    industry { "technology" }
    value_proposition { "We provide innovative solutions" }
    mission { "To make technology accessible" }
    voice { "professional" }
    content_language { "en" }
    region { "north_america" }

    # JSON fields - use default values from schema
    guardrails { { "tone_no_go" => [], "banned_words" => [], "claims_rules" => "" } }
    resources { { "kling" => false, "stock" => false, "budget" => false, "editing" => false, "ai_avatars" => false, "podcast_clips" => false } }
  end
end
