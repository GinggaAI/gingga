FactoryBot.define do
  factory :brand_channel do
    association :brand
    platform { :instagram }
    handle { "@#{Faker::Internet.username}" }
    priority { 1 }

    trait :instagram do
      platform { :instagram }
      handle { "@#{Faker::Internet.username}" }
    end

    trait :tiktok do
      platform { :tiktok }
      handle { "@#{Faker::Internet.username}" }
    end

    trait :youtube do
      platform { :youtube }
      handle { "#{Faker::Internet.username}" }
    end

    trait :linkedin do
      platform { :linkedin }
      handle { Faker::Internet.username }
    end
  end
end
