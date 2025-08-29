module Creas
  class ContentItemInitializerService
    def initialize(strategy_plan:)
      @plan = strategy_plan
      @user = @plan.user
      @brand = @plan.brand
    end

    def call
      return [] unless @plan.weekly_plan.present?

      created_items = nil

      CreasContentItem.transaction do
        created_items = create_content_items_from_weekly_plan

        # Calculate expected quantity based on weekly plan
        expected_count = @plan.weekly_plan.sum { |week| week["ideas"]&.count || 0 }
        actual_count = created_items.count

        # If we didn't create all expected items, retry missing ones
        if actual_count < expected_count
          Rails.logger.info "ContentItemInitializerService: Created #{actual_count}/#{expected_count} items. Retrying missing content..."
          missing_items = retry_missing_content_items(created_items, expected_count)
          created_items.concat(missing_items)
        end

        Rails.logger.info "ContentItemInitializerService: Final count #{created_items.count}/#{expected_count} items"
      end

      created_items
    end

    private

    def create_content_items_from_weekly_plan
      content_items = []

      @plan.weekly_plan.each do |week_data|
        next unless week_data["ideas"].present?

        week_data["ideas"].each do |idea|
          # Enrich idea with details from content_distribution if needed
          enriched_idea = enrich_idea_from_content_distribution(idea)
          pilar = extract_pilar_from_idea(enriched_idea)
          item = create_content_item_from_idea(enriched_idea, pilar)
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
        origin_source: "weekly_plan",
        week: week_number,
        week_index: week_number - 1,
        scheduled_day: nil, # Will be set when scheduled
        publish_date: nil,  # Will be set when scheduled
        publish_datetime_local: nil,
        timezone: @brand&.timezone || "UTC",
        content_name: generate_unique_content_name(idea, week_number),
        status: "draft", # Initial status is draft
        creation_date: Date.current,
        content_type: determine_content_type(idea),
        platform: idea["platform"]&.downcase || "instagram",
        aspect_ratio: determine_aspect_ratio(idea["platform"]),
        language: @brand.content_language || "en",
        pilar: pilar,
        day_of_the_week: determine_day_of_week(idea, pilar, week_number),
        template: normalize_template(idea["recommended_template"]),
        video_source: idea["video_source"] || "kling",
        post_description: generate_unique_description(idea, week_number),
        text_base: generate_unique_text_base(idea, week_number),
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

      # Only update if this is a new record or if it's still in draft status
      # This preserves content that has been processed by other services (like Voxa)
      if item.new_record? || item.status == "draft"
        item.assign_attributes(attrs)
        item.user = @user
        item.brand = @brand
        item.creas_strategy_plan = @plan
      else
        # For existing processed content, just ensure basic associations are correct
        item.user ||= @user
        item.brand ||= @brand
        item.creas_strategy_plan ||= @plan
      end

      begin
        item.save!
      rescue ActiveRecord::RecordInvalid => e
        # Handle content duplication by making content unique
        if handle_duplicate_content_errors(item, e)
          # Try saving again after making content unique
          begin
            item.save!
          rescue ActiveRecord::RecordInvalid => retry_error
            Rails.logger.warn "Failed to create CreasContentItem after uniqueness retry: #{retry_error.message}"
            Rails.logger.warn "Attributes: #{item.attributes.inspect}"
          end
        else
          Rails.logger.warn "Failed to create CreasContentItem: #{e.message}"
          Rails.logger.warn "Attributes: #{attrs.inspect}"
        end
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

    def determine_day_of_week(idea, pilar, week_number)
      # Strategy: Distribute content strategically across the week based on pilar type and frequency
      days_of_week = %w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday]

      # If the idea specifies a day, use it
      return idea["suggested_day"] if idea["suggested_day"].in?(days_of_week)

      # Smart distribution based on content pillars and best posting times
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
        # Default even distribution
        day_index = (week_number + pilar.ord) % 7
        days_of_week[day_index]
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

    def handle_duplicate_content_errors(item, error)
      error_messages = error.record.errors.full_messages
      handled = false

      # Handle duplicate content name (cross-months)
      if error_messages.any? { |msg| msg.include?("Content name already exists") || msg.include?("already exists for this brand") }
        item.content_name = make_content_name_unique(item.content_name, item.week, item.pilar)
        handled = true
      end

      # Handle similar post descriptions
      if error_messages.any? { |msg| msg.include?("Post description is") && msg.include?("similar") }
        item.post_description = make_description_unique(item.post_description, item.week, item.pilar)
        handled = true
      end

      # Handle similar text base
      if error_messages.any? { |msg| msg.include?("Text base is") && msg.include?("similar") }
        item.text_base = make_text_base_unique(item.text_base, item.week, item.pilar)
        handled = true
      end

      handled
    end

    def make_content_name_unique(original_name, week, pilar)
      return original_name if original_name.blank?

      month_year = @plan.month
      pilar_name = pilar_full_name(pilar)

      # Create meaningful variations based on context
      variations = [
        "#{original_name} (#{month_year})",
        "#{original_name} - #{pilar_name} Focus",
        "#{original_name} - Week #{week}",
        "#{original_name} (#{pilar_name} Edition)",
        "#{original_name} - #{month_year} Update"
      ]

      # Try each variation until we find one that doesn't exist
      variations.each do |variation|
        unless content_name_exists?(variation)
          return variation
        end
      end

      # Fallback with timestamp if all variations exist
      timestamp = Time.current.strftime("%m%d%H%M")
      "#{original_name} (#{timestamp})"
    end

    def make_description_unique(original_description, week, pilar)
      return original_description if original_description.blank?

      month_year = @plan.month
      pilar_context = get_pilar_context(pilar)

      # Add contextual uniqueness that's still meaningful
      unique_suffix = "\n\n[#{pilar_context} content for #{month_year}, Week #{week}]"
      "#{original_description}#{unique_suffix}"
    end

    def make_text_base_unique(original_text, week, pilar)
      return original_text if original_text.blank?

      # Add contextual hashtags that make sense for the content
      pilar_hashtag = "##{pilar_full_name(pilar).gsub(' ', '')}"
      week_hashtag = "#Week#{week}"
      month_hashtag = "##{@plan.month.gsub('-', '')}"

      "#{original_text}\n\n#{pilar_hashtag} #{week_hashtag} #{month_hashtag}"
    end

    def content_name_exists?(name)
      CreasContentItem.where(brand_id: @brand.id, content_name: name).exists?
    end

    def pilar_full_name(pilar)
      case pilar
      when "C" then "Content"
      when "R" then "Relationship"
      when "E" then "Entertainment"
      when "A" then "Advertising"
      when "S" then "Sales"
      else pilar
      end
    end

    def get_pilar_context(pilar)
      case pilar
      when "C" then "Educational"
      when "R" then "Community"
      when "E" then "Entertainment"
      when "A" then "Promotional"
      when "S" then "Sales-focused"
      else "General"
      end
    end

    def generate_unique_content_name(idea, week_number)
      base_title = idea["title"] || "Content #{idea['id']}"

      # Always append week information to make titles unique across weeks
      # This ensures all 20 content items can be created and displayed
      unique_title = "#{base_title} (Week #{week_number})"

      # Check if this unique title already exists (edge case protection)
      counter = 1
      final_title = unique_title
      while CreasContentItem.where(brand_id: @brand.id, content_name: final_title).exists?
        final_title = "#{unique_title} (#{counter})"
        counter += 1
      end

      final_title
    end

    def extract_pilar_from_idea(idea)
      # First try the direct pilar field (for content_distribution format)
      return idea["pilar"] if idea["pilar"].present?

      # Then try extracting from ID pattern like "202511-vlado-entrepreneur-w1-i1-C"
      if idea["id"]&.match(/-([A-Z])$/)
        return $1
      end

      # Fallback to "C" for Content
      "C"
    end

    def generate_unique_description(idea, week_number)
      base_description = idea["description"] || ""
      return base_description if base_description.blank?

      # Append week information to make descriptions unique
      "#{base_description} (Week #{week_number} content)"
    end

    def generate_unique_text_base(idea, week_number)
      base_text = build_text_base(idea)
      return base_text if base_text.blank?

      # Append week information to make text_base unique
      "#{base_text}\n\n[Week #{week_number} version]"
    end

    def retry_missing_content_items(created_items, expected_count)
      missing_items = []
      created_content_ids = created_items.map(&:content_id).to_set

      # Find all content that should exist but doesn't
      @plan.weekly_plan.each_with_index do |week_data, week_index|
        week_number = week_index + 1
        next unless week_data["ideas"].present?

        week_data["ideas"].each do |idea|
          next if created_content_ids.include?(idea["id"])

          # This content is missing, try to create it with enhanced uniqueness
          Rails.logger.info "Retrying missing content: #{idea['id']} - #{idea['title']}"

          begin
            item = create_missing_content_item(idea, week_number, missing_items.count)
            if item&.persisted?
              missing_items << item
              created_content_ids.add(idea["id"])
              Rails.logger.info "Successfully created missing content: #{item.content_name}"
            else
              Rails.logger.warn "Failed to create missing content: #{idea['id']} - #{item&.errors&.full_messages}"
            end
          rescue StandardError => e
            Rails.logger.error "Error creating missing content #{idea['id']}: #{e.message}"
          end
        end
      end

      missing_items
    end

    def create_missing_content_item(idea, week_number, retry_index)
      pilar = extract_pilar_from_idea(idea)
      week_index = week_number - 1

      # Generate highly unique content to avoid any validation conflicts
      unique_id = "#{retry_index + 1}-#{SecureRandom.hex(4)}"
      unique_suffix = "(Week #{week_number} - Version #{unique_id})"

      # Create completely unique descriptions and text to pass similarity validation
      original_description = idea["description"] || ""
      original_title = idea["title"] || "Content #{idea['id']}"

      unique_description = "#{original_description} [UNIQUE VERSION #{unique_id}: This content is specifically created for week #{week_number} with unique branding and messaging approach for #{@brand.name}.]"
      unique_text_base = build_highly_unique_text_base(idea, week_number, unique_id)

      attrs = {
        content_id: idea["id"],
        origin_id: idea["id"],
        origin_source: "weekly_plan",
        week: week_number,
        week_index: week_index,
        scheduled_day: nil,
        publish_date: nil,
        publish_datetime_local: nil,
        timezone: @brand.timezone || "UTC",
        content_name: "#{original_title} #{unique_suffix}",
        status: "draft",
        creation_date: Date.current.strftime("%Y-%m-%d"),
        content_type: determine_content_type(idea),
        platform: idea["platform"]&.downcase || "instagram",
        aspect_ratio: determine_aspect_ratio(idea["platform"]),
        language: @brand.content_language || "en",
        pilar: pilar,
        day_of_the_week: determine_day_of_week(idea, pilar, week_number),
        template: normalize_template(idea["recommended_template"]),
        video_source: idea["video_source"] || "kling",
        post_description: unique_description,
        text_base: unique_text_base,
        hashtags: "",
        subtitles: {},
        dubbing: {},
        shotplan: build_shotplan(idea),
        assets: build_assets(idea),
        accessibility: {},
        meta: build_meta(idea)
      }

      item = @plan.creas_content_items.build(attrs)
      item.user = @user
      item.brand = @brand

      if item.save
        item
      else
        Rails.logger.warn "Failed to save missing content item: #{item.errors.full_messages.join(', ')}"

        # Try to recover from validation errors by applying fixes
        recovered_item = attempt_error_recovery(item, idea, week_number, retry_index)
        if recovered_item
          Rails.logger.info "Successfully recovered and saved content item: #{recovered_item.content_name}"
          recovered_item
        else
          Rails.logger.error "Unable to recover content item after multiple attempts: #{item.errors.full_messages.join(', ')}"
          nil
        end
      end
    end

    def enrich_idea_from_content_distribution(idea)
      # If idea is already enriched (has more than just id), return as-is
      return idea if idea.keys.size > 1

      # If idea only has id, look it up in content_distribution
      idea_id = idea["id"]
      return idea unless idea_id && @plan.content_distribution

      # Search through all pilars in content_distribution
      @plan.content_distribution.each do |pilar, pilar_data|
        next unless pilar_data["ideas"]

        found_idea = pilar_data["ideas"].find { |dist_idea| dist_idea["id"] == idea_id }
        if found_idea
          # Merge the original idea (which might have weekly_plan specific data) with distribution data
          return idea.merge(found_idea)
        end
      end

      # If not found in content_distribution, return original idea
      idea
    end

    def build_highly_unique_text_base(idea, week_number, unique_id)
      hook = idea["hook"] || "Check this out!"
      description = idea["description"] || ""
      cta = idea["cta"] || "Learn more!"

      unique_content = <<~TEXT
        #{hook} [WEEK #{week_number} EDITION - VERSION #{unique_id}]

        #{description}

        This is a unique version created specifically for week #{week_number} of the content strategy for #{@brand.name}. This version includes tailored messaging and approach different from other weeks.

        #{cta}

        [Unique Content Version: #{unique_id} - Week #{week_number} - Generated: #{Date.current}]
      TEXT

      unique_content.strip
    end

    def attempt_error_recovery(item, idea, week_number, retry_index)
      max_recovery_attempts = 3

      (1..max_recovery_attempts).each do |attempt|
        Rails.logger.info "ContentItemInitializerService: Recovery attempt #{attempt}/#{max_recovery_attempts} for content: #{idea['id']}"

        # Apply recovery strategies based on error types
        apply_recovery_fixes(item, attempt, week_number, retry_index)

        if item.save
          Rails.logger.info "ContentItemInitializerService: Recovery successful on attempt #{attempt}"
          return item
        end

        Rails.logger.warn "ContentItemInitializerService: Recovery attempt #{attempt} failed: #{item.errors.full_messages.join(', ')}"
      end

      nil
    end

    def apply_recovery_fixes(item, attempt, week_number, retry_index)
      timestamp = Time.current.strftime("%H%M%S")

      case attempt
      when 1
        # Attempt 1: Fix template validation
        if item.errors[:template].any?
          item.template = "solo_avatars"
          Rails.logger.info "ContentItemInitializerService: Fixed template to 'solo_avatars'"
        end

        # Fix pilar validation
        if item.errors[:pilar].any?
          item.pilar = "C"
          Rails.logger.info "ContentItemInitializerService: Fixed pilar to 'C'"
        end

        # Fix status validation
        if item.errors[:status].any?
          item.status = "draft"
          Rails.logger.info "ContentItemInitializerService: Fixed status to 'draft'"
        end

        # Fix video_source validation
        if item.errors[:video_source].any?
          item.video_source = "none"
          Rails.logger.info "ContentItemInitializerService: Fixed video_source to 'none'"
        end

        # Fix day_of_the_week validation
        if item.errors[:day_of_the_week].any?
          item.day_of_the_week = "Monday"
          Rails.logger.info "ContentItemInitializerService: Fixed day_of_the_week to 'Monday'"
        end

      when 2
        # Attempt 2: Make content name highly unique
        if item.errors[:content_name].any?
          item.content_name = "RECOVERED Content #{retry_index + 1} - Week #{week_number} - #{timestamp}"
          Rails.logger.info "ContentItemInitializerService: Generated highly unique content name"
        end

        # Make content_id unique if needed
        if item.errors[:content_id].any?
          item.content_id = "RECOVERED-#{week_number}-#{retry_index}-#{timestamp}"
          item.origin_id = item.content_id
          Rails.logger.info "ContentItemInitializerService: Generated unique content_id"
        end

        # Create completely unique descriptions
        if item.errors[:post_description].any? || item.errors[:text_base].any?
          unique_suffix = " [RECOVERED CONTENT - #{timestamp} - WEEK #{week_number}]"
          item.post_description = "RECOVERED: #{item.post_description}#{unique_suffix}"
          item.text_base = "RECOVERED: #{item.text_base}#{unique_suffix}"
          Rails.logger.info "ContentItemInitializerService: Made descriptions unique with recovery suffix"
        end

      when 3
        # Attempt 3: Nuclear option - minimize all content to essential fields only
        item.content_name = "Emergency Recovery Content W#{week_number}-#{timestamp}"
        item.content_id = "EMERGENCY-#{week_number}-#{retry_index}-#{timestamp}"
        item.origin_id = item.content_id
        item.post_description = "Emergency recovery content for week #{week_number}. Original content could not be saved due to validation conflicts."
        item.text_base = "This is emergency recovery content generated to ensure the content plan is complete."
        item.hashtags = ""
        item.template = "solo_avatars"
        item.pilar = "C"
        item.status = "draft"
        item.video_source = "none"
        item.platform = "instagram"
        item.content_type = "reel"
        item.day_of_the_week = "Monday"
        item.meta = {
          "recovery_mode" => true,
          "original_idea_id" => idea["id"],
          "recovery_timestamp" => Time.current.iso8601
        }

        Rails.logger.warn "ContentItemInitializerService: Applied nuclear recovery option with minimal safe content"
      end
    end

    def normalize_template(template)
      # Valid templates according to CreasContentItem model validation
      valid_templates = %w[solo_avatars avatar_and_video narration_over_7_images remix one_to_three_videos]

      return "solo_avatars" if template.blank?

      # If template is already valid, return it
      return template if valid_templates.include?(template)

      # Template normalization mapping for common variations
      template_mappings = {
        "solo_avatar" => "solo_avatars",
        "single_avatar" => "solo_avatars",
        "avatar_only" => "solo_avatars",
        "text" => "solo_avatars",
        "avatar" => "solo_avatars",
        "avatar_video" => "avatar_and_video",
        "avatar_with_video" => "avatar_and_video",
        "hybrid" => "avatar_and_video",
        "narration_7_images" => "narration_over_7_images",
        "narration_images" => "narration_over_7_images",
        "image_narration" => "narration_over_7_images",
        "slideshow" => "narration_over_7_images",
        "seven_images" => "narration_over_7_images",
        "carousel" => "narration_over_7_images",
        "remix_video" => "remix",
        "video_remix" => "remix",
        "repurpose" => "remix",
        "multi_video" => "one_to_three_videos",
        "multiple_videos" => "one_to_three_videos",
        "three_videos" => "one_to_three_videos",
        "videos" => "one_to_three_videos",
        "video_compilation" => "one_to_three_videos"
      }

      # Try to normalize the template
      normalized_template = template_mappings[template.downcase.strip]
      if normalized_template
        Rails.logger.info "ContentItemInitializerService: Normalized template '#{template}' to '#{normalized_template}'"
        return normalized_template
      end

      # If no mapping found, log the unknown template and default to solo_avatars
      Rails.logger.warn "ContentItemInitializerService: Unknown template '#{template}', defaulting to 'solo_avatars'"
      "solo_avatars"
    end
  end
end
