FactoryBot.define do
  factory :creas_post do
    association :user
    association :creas_strategy_plan
    origin_id { "#{Date.current.strftime('%Y%m')}-test-brand-w1-i1-C" }
    content_name { "#{Faker::Lorem.words(number: 3).join(' ').titleize}" }
    status { "in_production" }
    creation_date { Date.current }
    publish_date { Date.current + 3.days }
    publish_datetime_local { "#{publish_date}T18:00:00" }
    timezone { "America/New_York" }
    content_type { "Video" }
    platform { "Instagram Reels" }
    aspect_ratio { "9:16" }
    language { "en-US" }
    subtitles { { mode: "platform_auto", languages: [ "en-US" ] } }
    dubbing { { enabled: false, languages: [] } }
    pilar { %w[C R E A S].sample }
    template { %w[solo_avatars avatar_and_video narration_over_7_images remix one_to_three_videos].sample }
    video_source { %w[none external kling].sample }
    post_description { Faker::Lorem.paragraph }
    text_base { Faker::Lorem.paragraph }
    hashtags { "#marketing #business #growth" }
    shotplan do
      {
        scenes: [
          { id: 1, role: "Hook", type: "avatar", visual: "Professional setup", on_screen_text: "Hook text", voiceover: "Hook voiceover" },
          { id: 2, role: "Development", type: "avatar", visual: "Explaining concept", on_screen_text: "Main content", voiceover: "Main voiceover" },
          { id: 3, role: "Close", type: "avatar", visual: "Call to action", on_screen_text: "CTA text", voiceover: "CTA voiceover" }
        ]
      }
    end
    assets { { external_video_url: "", video_prompts: [], broll_suggestions: [] } }
    accessibility { { captions: true, srt_export: true, on_screen_text_max_chars: 42 } }
    kpi_focus { %w[reach saves comments CTR DM].sample }
    success_criteria { "≥8% saves" }
    compliance_check { "ok" }
    raw_payload { { source: "voxa" } }
    meta { { model: "gpt-4o-mini", prompt_version: "voxa-v1" } }
  end
end
