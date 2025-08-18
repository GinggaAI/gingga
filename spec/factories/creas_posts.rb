FactoryBot.define do
  factory :creas_post do
    association :user
    association :creas_strategy_plan

    content_name { "Test Content" }
    status { "draft" }
    creation_date { Date.current }
    publish_date { Date.current + 1.day }
    content_type { "Video" }
    platform { "Instagram Reels" }
    pilar { "Test Pilar" }
    template { "Test Template" }
    video_source { "Test Source" }
    post_description { "Test Description" }
    text_base { "Test Text Base" }
    hashtags { "#test #content" }
    aspect_ratio { "9:16" }

    # JSONB fields with default empty hashes
    assets { {} }
    shotplan { {} }
    accessibility { {} }
    dubbing { {} }
    raw_payload { {} }
    meta { {} }
    subtitles { {} }
  end
end
