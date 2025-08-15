FactoryBot.define do
  factory :creas_strategy_plan do
    association :user
    association :brand
    strategy_name { "Test Strategy" }
    month { "2025-08" }
    objective_of_the_month { "Increase brand awareness" }
    frequency_per_week { 3 }
    monthly_themes { [ "innovation", "technology" ] }
    resources_override { {} }
    content_distribution { {} }
    weekly_plan { [] }
    remix_duet_plan { {} }
    publish_windows_local { {} }
    brand_snapshot { {} }
    raw_payload { {} }
    meta { {} }
  end
end
