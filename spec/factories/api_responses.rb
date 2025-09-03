FactoryBot.define do
  factory :api_response do
    provider { "MyString" }
    endpoint { "MyString" }
    request_data { "MyText" }
    response_data { "MyText" }
    status_code { 1 }
    response_time_ms { 1 }
    user { nil }
    created_at { "2025-09-03 16:12:47" }
  end
end
