FactoryBot.define do
  factory :reel do
    association :user
    mode { 'scene_based' }
    status { 'draft' }
  end
end