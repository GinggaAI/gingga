module Creas
  class ContentItemInitializerService
    def initialize(strategy_plan:)
      @plan = strategy_plan
      @user = @plan.user
      @brand = @plan.brand
    end

    def call
      return [] unless @plan.content_distribution.present?

      CreasContentItem.transaction do
        create_content_items_from_distribution
      end
    end

    private

    def create_content_items_from_distribution
      content_items = []

      @plan.content_distribution.each do |pilar, pilar_data|
        next unless pilar_data["ideas"].present?

        pilar_data["ideas"].each do |idea|
          item = create_content_item_from_idea(idea, pilar)
          content_items << item if item.persisted?
        end
      end

      content_items
    end

    def create_content_item_from_idea(idea, pilar)
      # Extract week number from idea ID or weekly_plan
      week_number = extract_week_from_idea(idea)

      attrs = {
        content_id: idea["id"],
        origin_id: idea["id"],
        origin_source: "content_distribution",
        week: week_number,
        week_index: week_number - 1,
        scheduled_day: nil, # Will be set when scheduled
        publish_date: nil,  # Will be set when scheduled
        publish_datetime_local: nil,
        timezone: @brand&.timezone || "UTC",
        content_name: idea["title"] || "Content #{idea['id']}",
        status: "draft", # Initial status is draft
        creation_date: Date.current,
        content_type: determine_content_type(idea),
        platform: idea["platform"]&.downcase || "instagram",
        aspect_ratio: determine_aspect_ratio(idea["platform"]),
        language: @brand.content_language || "en",
        pilar: pilar,
        template: idea["recommended_template"] || "solo_avatars",
        video_source: idea["video_source"] || "kling",
        post_description: idea["description"] || "",
        text_base: build_text_base(idea),
        hashtags: "", # Will be generated later
        subtitles: {},
        dubbing: {},
        shotplan: build_shotplan(idea),
        assets: build_assets(idea),
        accessibility: {},
        meta: build_meta(idea)
      }

      # Find or create the record
      item = CreasContentItem.find_or_initialize_by(content_id: attrs[:content_id])
      item.assign_attributes(attrs)
      item.user = @user
      item.brand = @brand
      item.creas_strategy_plan = @plan

      begin
        item.save!
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.warn "Failed to create CreasContentItem: #{e.message}"
        Rails.logger.warn "Attributes: #{attrs.inspect}"
      end

      item
    end

    def extract_week_from_idea(idea)
      # Try to extract from weekly_plan first
      @plan.weekly_plan.each_with_index do |week_data, index|
        if week_data["ideas"]&.any? { |w_idea| w_idea["id"] == idea["id"] }
          return index + 1
        end
      end

      # Fallback: try to extract from ID pattern like "202508-gingga-A-w1-i1"
      if idea["id"]&.match(/w(\d+)/)
        return $1.to_i
      end

      # Default to week 1
      1
    end

    def determine_content_type(idea)
      # Map from platform and context to content type
      platform = idea["platform"]&.downcase

      case platform
      when "instagram"
        "reel" # Most Instagram content in the system are reels
      when "tiktok"
        "video"
      when "youtube"
        "video"
      else
        "post"
      end
    end

    def determine_aspect_ratio(platform)
      case platform&.downcase
      when "instagram", "tiktok"
        "9:16" # Vertical
      when "youtube"
        "16:9" # Horizontal
      else
        "1:1" # Square
      end
    end

    def build_text_base(idea)
      parts = []
      parts << idea["hook"] if idea["hook"].present?
      parts << idea["description"] if idea["description"].present?
      parts << idea["cta"] if idea["cta"].present?

      parts.join("\n\n")
    end

    def build_shotplan(idea)
      shotplan = {}

      if idea["beats_outline"].present?
        shotplan["beats"] = idea["beats_outline"].map.with_index do |beat, index|
          {
            "beat_number" => index + 1,
            "description" => beat,
            "duration" => "3-5s"
          }
        end
      end

      if idea["assets_hints"].present?
        shotplan["scenes"] = build_scenes_from_hints(idea["assets_hints"])
      end

      shotplan
    end

    def build_scenes_from_hints(hints)
      scenes = []

      if hints["video_prompts"].present?
        hints["video_prompts"].each_with_index do |prompt, index|
          scenes << {
            "scene_number" => index + 1,
            "description" => prompt,
            "visual_elements" => hints["broll_suggestions"] || []
          }
        end
      end

      scenes
    end

    def build_assets(idea)
      assets = {}

      if idea["assets_hints"].present?
        hints = idea["assets_hints"]

        assets["video_prompts"] = hints["video_prompts"] || []
        assets["broll_suggestions"] = hints["broll_suggestions"] || []

        if hints["external_video_url"].present?
          assets["external_video_url"] = hints["external_video_url"]
        end

        if hints["external_video_notes"].present?
          assets["external_video_notes"] = hints["external_video_notes"]
        end
      end

      assets
    end

    def build_meta(idea)
      {
        "kpi_focus" => idea["kpi_focus"],
        "success_criteria" => idea["success_criteria"],
        "compliance_check" => "pending",
        "visual_notes" => idea["visual_notes"],
        "hook" => idea["hook"],
        "cta" => idea["cta"],
        "repurpose_to" => idea["repurpose_to"] || [],
        "language_variants" => idea["language_variants"] || []
      }
    end
  end
end
