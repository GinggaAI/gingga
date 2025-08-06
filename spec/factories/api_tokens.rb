FactoryBot.define do
  factory :api_token do
    provider { "openai" }
    mode { "production" }
    encrypted_token { "sk-test_token_#{SecureRandom.hex(8)}" }
    user { association :user }

    trait :openai do
      provider { "openai" }
      encrypted_token { "sk-#{SecureRandom.hex(24)}" }
    end

    trait :heygen do
      provider { "heygen" }
      encrypted_token { "hg_#{SecureRandom.hex(20)}" }
    end

    trait :kling do
      provider { "kling" }
      encrypted_token { "kl_#{SecureRandom.hex(20)}" }
    end

    trait :test_mode do
      mode { "test" }
    end

    trait :production_mode do
      mode { "production" }
    end

    trait :invalid_token do
      is_valid { false }
    end

    # Note: Mocking should be done in individual tests, not in factories
  end
end
