FactoryBot.define do
  factory :brand do
    association :user
    name { "#{Faker::Company.name} Co" }
    slug { name.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/^-|-$/, '') }
    industry { Faker::Commerce.department }
    value_proposition { Faker::Lorem.paragraph }
    mission { Faker::Lorem.paragraph }
    voice { %w[friendly professional authoritative casual].sample }
    content_language { "en-US" }
    account_language { "en-US" }
    subtitle_languages { %w[en-US es-ES] }
    dub_languages { %w[en-US] }
    region { "North America" }
    timezone { "America/New_York" }
    guardrails { { banned_words: [ "banned" ], claims_rules: "No health claims", tone_no_go: [ "aggressive" ] } }
    resources { { podcast_clips: true, editing: false, ai_avatars: true, kling: false, stock: true, budget: false } }
  end
end
