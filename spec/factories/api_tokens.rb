FactoryBot.define do
  factory :api_token do
    provider { "openai" }
    mode { "production" }
    encrypted_token { "sk-test_token_#{SecureRandom.hex(8)}" }
    user { association :user }
    valid { true }

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
      valid { false }
    end

    before(:create) do |api_token|
      allow_any_instance_of(ApiTokenValidatorService).to receive(:call)
        .and_return({ valid: true })
    end
  end
end
