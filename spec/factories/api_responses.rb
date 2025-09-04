FactoryBot.define do
  factory :api_response do
    user
    provider { 'heygen' }
    endpoint { '/v2/avatars' }
    request_data { { headers: { "X-API-KEY" => "[REDACTED]" }, query: {} }.to_json }
    response_data { { code: 100, data: { avatars: [] } }.to_json }
    status_code { 200 }
    response_time_ms { 150 }
    success { true }
    error_message { nil }

    trait :heygen do
      provider { 'heygen' }
      endpoint { '/v2/avatars' }
    end

    trait :openai do
      provider { 'openai' }
      endpoint { '/v1/chat/completions' }
    end

    trait :kling do
      provider { 'kling' }
      endpoint { '/v1/videos' }
    end

    trait :successful do
      success { true }
      status_code { 200 }
      error_message { nil }
    end

    trait :failed do
      success { false }
      status_code { 401 }
      error_message { 'Unauthorized' }
      response_data { { error: 'Invalid API key' }.to_json }
    end

    trait :slow_response do
      response_time_ms { 5000 }
    end

    trait :with_avatar_data do
      response_data do
        {
          code: 100,
          data: {
            avatars: [
              {
                avatar_id: 'avatar_123',
                avatar_name: 'Test Avatar',
                preview_image_url: 'https://example.com/avatar.jpg',
                gender: 'female',
                is_public: true
              }
            ]
          }
        }.to_json
      end
    end
  end
end
