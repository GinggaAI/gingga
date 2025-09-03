FactoryBot.define do
  factory :avatar do
    user
    avatar_id { "avatar_#{Faker::Alphanumeric.alphanumeric(number: 10)}" }
    name { Faker::Name.name }
    provider { 'heygen' }
    status { 'active' }
    preview_image_url { Faker::Internet.url }
    gender { %w[male female].sample }
    is_public { [ true, false ].sample }
    raw_response { { "avatar_id" => avatar_id, "avatar_name" => name }.to_json }

    trait :heygen do
      provider { 'heygen' }
    end

    trait :kling do
      provider { 'kling' }
    end

    trait :inactive do
      status { 'inactive' }
    end

    trait :male do
      gender { 'male' }
    end

    trait :female do
      gender { 'female' }
    end

    trait :public do
      is_public { true }
    end

    trait :private do
      is_public { false }
    end
  end
end
