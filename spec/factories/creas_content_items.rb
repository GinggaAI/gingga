FactoryBot.define do
  factory :creas_content_item do
    association :creas_strategy_plan
    association :user
    association :brand

    sequence(:content_id) { |n| "20250819-w1-i#{n}" }
    origin_id { "202508-acme-w1-i1-C" }
    origin_source { "weekly_plan" }
    week { 1 }
    scheduled_day { "Monday" }
    publish_date { Date.current + 3.days }
    publish_datetime_local { Time.current + 3.days }
    timezone { "Europe/Madrid" }
    content_name { "Sample Content Item" }
    status { "in_production" }
    creation_date { Date.current }
    content_type { "Video" }
    platform { "Instagram Reels" }
    aspect_ratio { "9:16" }
    language { "en-US" }
    pilar { "C" }
    template { "solo_avatars" }
    video_source { "none" }
    post_description { "This is a sample post description" }
    text_base { "This is the text base for the content" }
    hashtags { "#content #creation #test" }
    subtitles { { "mode" => "platform_auto", "languages" => [ "en-US" ] } }
    dubbing { { "enabled" => false, "languages" => [] } }
    shotplan {
      {
        "scenes" => [
          {
            "id" => 1,
            "role" => "Hook",
            "type" => "avatar",
            "visual" => "Close-up shot",
            "on_screen_text" => "Hook text",
            "voiceover" => "Hook voiceover",
            "avatar_id" => "avatar_123",
            "voice_id" => "voice_123"
          }
        ],
        "beats" => []
      }
    }
    assets {
      {
        "external_video_url" => "",
        "video_urls" => [],
        "video_prompts" => [],
        "broll_suggestions" => []
      }
    }
    accessibility { { "captions" => true, "srt_export" => true } }
    meta { { "kpi_focus" => "reach", "success_criteria" => "≥8% saves" } }

    trait :with_external_video do
      template { "remix" }
      video_source { "external" }
      assets {
        {
          "external_video_url" => "https://example.com/video.mp4",
          "video_urls" => [ "https://example.com/video.mp4" ],
          "video_prompts" => [],
          "broll_suggestions" => []
        }
      }
    end

    trait :with_kling_video do
      template { "one_to_three_videos" }
      video_source { "kling" }
      assets {
        {
          "external_video_url" => "",
          "video_urls" => [],
          "video_prompts" => [ "A beautiful sunset over mountains" ],
          "broll_suggestions" => []
        }
      }
    end

    trait :with_narration do
      template { "narration_over_7_images" }
      shotplan {
        {
          "scenes" => [],
          "beats" => (1..7).map do |i|
            {
              "idx" => i,
              "image_prompt" => "Image prompt #{i}",
              "voiceover" => "Voiceover #{i}"
            }
          end
        }
      }
    end

    trait :ready_for_review do
      status { "ready_for_review" }
    end

    trait :approved do
      status { "approved" }
    end
  end
end
