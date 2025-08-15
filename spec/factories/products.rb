FactoryBot.define do
  factory :product do
    association :brand
    name { "Test Product" }
    description { "A great product for testing" }
    pricing_info { "$99/month" }
    url { "https://example.com/product" }
  end
end
