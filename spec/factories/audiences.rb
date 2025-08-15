FactoryBot.define do
  factory :audience do
    association :brand
    name { "Primary Audience" }
    demographic_profile { { "age_range" => "25-34", "gender" => "all", "location" => "global" } }
    interests { [ "technology", "innovation", "productivity" ] }
    digital_behavior { [ "social_media_active", "early_adopter" ] }
  end
end
