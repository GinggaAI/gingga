FactoryBot.define do
  factory :audience do
    association :brand
    name { "#{Faker::Demographic.demonym} Professionals" }
    demographic_profile do
      {
        age_range: "25-35",
        gender: "mixed",
        location: "urban",
        income_level: "middle-class"
      }
    end
    interests { [ "technology", "business", "lifestyle" ] }
    digital_behavior { [ "active_on_instagram", "watches_reels", "engages_with_brands" ] }
  end
end
