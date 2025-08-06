FactoryBot.define do
  factory :reel_scene do
    association :reel
    sequence(:scene_number) { |n| ((n - 1) % 3) + 1 }
    avatar_id { "avatar_#{SecureRandom.hex(4)}" }
    voice_id { "voice_#{SecureRandom.hex(4)}" }
    script { "This is a sample script for scene #{scene_number}. Lorem ipsum dolor sit amet." }
  end
end