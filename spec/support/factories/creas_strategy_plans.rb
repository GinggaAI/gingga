FactoryBot.define do
  factory :creas_strategy_plan do
    association :user
    association :brand
    strategy_name { "#{Date.current.strftime('%B %Y')} Strategy" }
    month { Date.current.strftime('%Y-%m') }
    objective_of_the_month { %w[awareness engagement sales community].sample }
    frequency_per_week { 4 }
    monthly_themes { [ "product launch", "brand awareness" ] }
    resources_override { { ai_avatars: true, stock: false } }
    content_distribution { { "C" => { goal: "Growth", formats: [ "Video" ] } } }
    weekly_plan { [ { week: 1, publish_cadence: 4, ideas: [] } ] }
    remix_duet_plan { { rationale: "Increase reach", opportunities: [] } }
    publish_windows_local { { "instagram" => "18:00-20:00" } }
    brand_snapshot { { name: brand&.name || "Test Brand" } }
    raw_payload { { source: "noctua" } }
    meta { { model: "gpt-4o-mini", prompt_version: "noctua-v1" } }
  end
end
