FactoryBot.define do
  factory :brand_channel do
    association :brand
    platform { 0 } # Assuming enum values starting from 0
    handle { "@testbrand" }
    priority { 1 }
  end
end
