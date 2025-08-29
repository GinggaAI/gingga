FactoryBot.define do
  factory :ai_response do
    association :user
    service_name { "noctua" }
    ai_model { "gpt-4o" }
    prompt_version { "noctua-v1" }
    raw_request { { system: "test prompt", user: "test request" } }
    raw_response { { test: "response data" } }
    metadata { { brand_id: 1, month: "2025-08" } }
  end
end
