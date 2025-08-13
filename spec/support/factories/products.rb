FactoryBot.define do
  factory :product do
    association :brand
    name { Faker::Commerce.product_name }
    description { Faker::Lorem.paragraph }
    pricing_info { "$#{Faker::Commerce.price}" }
    url { Faker::Internet.url }
  end
end
