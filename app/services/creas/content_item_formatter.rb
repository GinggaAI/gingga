module Creas
  class ContentItemFormatter
    def initialize(content_item)
      @item = content_item
    end

    def self.call(content_item)
      new(content_item).to_h
    end

    def to_h
      return { error: "Content item not found" } unless @item

      {
        id: @item.content_id,
        origin_id: @item.origin_id,
        origin_source: @item.origin_source,
        week: @item.week,
        scheduled_day: @item.scheduled_day,
        content_name: @item.content_name,
        status: @item.status,
        creation_date: @item.creation_date&.iso8601,
        publish_date: @item.publish_date&.iso8601,
        publish_datetime_local: @item.publish_datetime_local&.iso8601,
        timezone: @item.timezone,
        content_type: @item.content_type,
        platform: @item.platform,
        aspect_ratio: @item.aspect_ratio,
        language: @item.language,
        pilar: @item.pilar,
        template: @item.template,
        video_source: @item.video_source,
        post_description: @item.post_description,
        text_base: @item.text_base,
        hashtags: @item.formatted_hashtags,
        subtitles: @item.subtitles,
        dubbing: @item.dubbing,
        accessibility: @item.accessibility,
        kpi_focus: @item.kpi_focus,
        success_criteria: @item.success_criteria,
        compliance_check: @item.compliance_check,
        meta: @item.meta,
        scenes: format_scenes,
        beats: format_beats,
        external_videos: @item.external_videos,
        video_prompts: extract_video_prompts,
        broll_suggestions: extract_broll_suggestions,
        screen_recording_instructions: extract_screen_recording_instructions
      }
    end

    private

    def format_scenes
      @item.scenes.map do |scene|
        {
          id: scene["id"],
          role: scene["role"],
          type: scene["type"],
          visual: scene["visual"],
          on_screen_text: scene["on_screen_text"],
          voiceover: scene["voiceover"],
          avatar_id: scene["avatar_id"],
          voice_id: scene["voice_id"],
          video_url: scene["video_url"],
          video_prompt: scene["video_prompt"]
        }
      end
    end

    def format_beats
      @item.beats.map do |beat|
        {
          idx: beat["idx"],
          image_prompt: beat["image_prompt"],
          voiceover: beat["voiceover"]
        }
      end
    end

    def extract_video_prompts
      @item.assets.dig("video_prompts") || []
    end

    def extract_broll_suggestions
      @item.assets.dig("broll_suggestions") || []
    end

    def extract_screen_recording_instructions
      @item.assets.dig("screen_recording_instructions") || ""
    end
  end
end
