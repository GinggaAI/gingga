module Creas
  class VoxaContentService
    def initialize(strategy_plan:)
      @plan = strategy_plan
      @user = @plan.user
      @brand = @plan.brand
    end

    def call
      strategy_plan_data = Creas::StrategyPlanFormatter.new(@plan).for_voxa
      brand_context = build_brand_context(@brand)

      system_msg = Creas::Prompts.voxa_system(strategy_plan_data: strategy_plan_data)
      user_msg = Creas::Prompts.voxa_user(strategy_plan_data: strategy_plan_data, brand_context: brand_context)

      payload = openai_chat!(system_msg: system_msg, user_msg: user_msg)
      persist_content_items!(payload.fetch("items"))
    rescue KeyError => e
      raise "Voxa response missing expected key: #{e.message}"
    rescue JSON::ParserError
      raise "Voxa returned non-JSON content"
    end

    private

    def build_brand_context(brand)
      {
        "brand" => {
          "industry" => brand.industry,
          "value_proposition" => brand.value_proposition,
          "mission" => brand.mission,
          "voice" => brand.voice,
          "priority_platforms" => extract_priority_platforms(brand),
          "languages" => {
            "content_language" => brand.content_language,
            "account_language" => brand.content_language || "en-US"
          },
          "guardrails" => brand.guardrails || {}
        }
      }
    end

    def openai_chat!(system_msg:, user_msg:)
      client = GinggaOpenAI::ChatClient.new(user: @user, model: "gpt-4o-mini", temperature: 0.5)
      response = client.chat!(system: system_msg, user: user_msg)
      JSON.parse(response)
    end

    def persist_content_items!(items)
      CreasContentItem.transaction do
        items.map { |item| upsert_item!(item) }
      end
    end

    def upsert_item!(item)
      attrs = map_voxa_item_to_attrs(item)
      rec = CreasContentItem.find_or_initialize_by(content_id: attrs[:content_id])

      # Preserve existing draft data while updating with Voxa refinements
      if rec.persisted? && rec.status == "draft"
        # Update status to in_production and merge new data
        attrs[:status] = "in_production"
        rec.assign_attributes(attrs)
      else
        # New record or already processed
        rec.assign_attributes(attrs)
      end

      rec.user = @user
      rec.brand = @brand
      rec.creas_strategy_plan = @plan
      rec.save!
      rec
    end

    def map_voxa_item_to_attrs(item)
      {
        content_id: item.fetch("id"),
        origin_id: item["origin_id"],
        origin_source: item["origin_source"],
        week: item.fetch("week"),
        week_index: item["week_index"],
        scheduled_day: item.dig("meta", "scheduled_day"),
        publish_date: parse_date(item.fetch("publish_date")),
        publish_datetime_local: parse_datetime(item["publish_datetime_local"]),
        timezone: item["timezone"],
        content_name: item.fetch("content_name"),
        status: item.fetch("status"),
        creation_date: parse_date(item.fetch("creation_date")),
        content_type: item.fetch("content_type"),
        platform: item.fetch("platform"),
        aspect_ratio: item["aspect_ratio"],
        language: item["language"],
        pilar: item.fetch("pilar"),
        template: item.fetch("template"),
        video_source: item.fetch("video_source"),
        post_description: item.fetch("post_description"),
        text_base: item.fetch("text_base"),
        hashtags: item.fetch("hashtags"),
        subtitles: item["subtitles"] || {},
        dubbing: item["dubbing"] || {},
        shotplan: item["shotplan"] || {},
        assets: item["assets"] || {},
        accessibility: item["accessibility"] || {},
        meta: (item["meta"] || {}).merge(
          hook: item["hook"],
          cta: item["cta"],
          kpi_focus: item["kpi_focus"],
          success_criteria: item["success_criteria"],
          compliance_check: item["compliance_check"]
        )
      }
    end

    def parse_date(date_string)
      return nil if date_string.blank?
      Date.iso8601(date_string)
    rescue Date::Error
      nil
    end

    def parse_datetime(datetime_string)
      return nil if datetime_string.blank?
      Time.zone.parse(datetime_string)
    rescue ArgumentError
      nil
    end

    def extract_priority_platforms(brand)
      platform_mapping = {
        "instagram" => "Instagram",
        "tiktok" => "TikTok",
        "youtube" => "YouTube",
        "linkedin" => "LinkedIn"
      }

      platforms = brand.brand_channels.pluck(:platform).map { |p| platform_mapping[p] || p.capitalize }.uniq
      platforms.any? ? platforms : [ "Instagram", "TikTok" ]
    end
  end
end
