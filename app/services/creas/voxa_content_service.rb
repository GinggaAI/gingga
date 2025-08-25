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

      # Save raw AI response for debugging
      AiResponse.create!(
        user: @user,
        service_name: "voxa",
        ai_model: "gpt-4o-mini",
        prompt_version: "voxa-2025-08-19",
        raw_request: {
          system: system_msg,
          user: user_msg,
          temperature: 0.5
        },
        raw_response: response,
        metadata: {
          strategy_plan_id: @plan.id,
          brand_id: @brand&.id
        }
      )

      JSON.parse(response)
    end

    def persist_content_items!(items)
      CreasContentItem.transaction do
        items.map { |item| upsert_item!(item) }
      end
    end

    def upsert_item!(item)
      attrs = map_voxa_item_to_attrs(item)
      # Use origin_id to find existing records created by ContentItemInitializerService
      origin_id = item["origin_id"]

      # First try to find by origin_id (preferred method)
      rec = nil
      if origin_id.present?
        rec = CreasContentItem.find_by(content_id: origin_id) ||
              CreasContentItem.find_by(origin_id: origin_id)
      end

      # If not found, try the new content_id
      rec ||= CreasContentItem.find_by(content_id: attrs[:content_id])

      # Initialize new record if still not found
      rec ||= CreasContentItem.new

      # Preserve existing draft data while updating with Voxa refinements
      if rec.persisted?
        # Update existing record with Voxa refinements
        attrs[:status] = "in_production"
        # Preserve the original content_id and origin_id when updating existing records
        attrs[:content_id] = rec.content_id
        attrs[:origin_id] = rec.origin_id
        # Preserve day_of_the_week assignment from original item
        attrs[:day_of_the_week] = rec.day_of_the_week if rec.day_of_the_week.present?
        rec.assign_attributes(attrs)
      else
        # New record - this should not happen if origin_id matching works correctly
        attrs[:content_id] = attrs[:content_id]
        attrs[:origin_id] = origin_id || attrs[:content_id]
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
        day_of_the_week: extract_day_of_week(item),
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

    def extract_day_of_week(item)
      # Check various possible sources for day information
      days_of_week = %w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday]

      # 1. Check if Voxa specifies a day directly
      day_from_voxa = item["day_of_the_week"] || item.dig("meta", "day_of_the_week")
      return day_from_voxa if day_from_voxa.in?(days_of_week)

      # 2. Check scheduled_day field
      scheduled_day = item.dig("meta", "scheduled_day") || item["scheduled_day"]
      return scheduled_day if scheduled_day.in?(days_of_week)

      # 3. Try to extract from publish_date if available
      publish_date = item["publish_date"]
      if publish_date.present?
        begin
          date = Date.parse(publish_date)
          return date.strftime("%A") # Returns full day name like "Monday"
        rescue Date::Error
          # Fall through to default logic
        end
      end

      # 4. Default: Use strategic distribution based on content pilar
      pilar = item["pilar"]
      week = item["week"] || 1

      case pilar
      when "C" # Content - Educational content performs well mid-week
        [ "Tuesday", "Wednesday", "Thursday" ].sample
      when "R" # Relationship - Community building content for weekends
        [ "Friday", "Saturday", "Sunday" ].sample
      when "E" # Entertainment - Fun content for peak engagement times
        [ "Monday", "Friday", "Saturday" ].sample
      when "A" # Advertising - Promotional content early in week
        [ "Monday", "Tuesday", "Wednesday" ].sample
      when "S" # Sales - Direct sales content mid-week when users are active
        [ "Tuesday", "Wednesday", "Thursday" ].sample
      else
        # Even distribution as fallback
        day_index = (week + (pilar&.ord || 0)) % 7
        days_of_week[day_index]
      end
    end
  end
end
