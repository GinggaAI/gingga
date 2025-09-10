module Creas
  module WeeklyDistributionValidator
    extend self

    def validate_weekly_distribution!(payload)
      weekly_plan = payload["weekly_plan"]
      frequency_per_week = payload["frequency_per_week"]

      unless weekly_plan.is_a?(Array) && weekly_plan.length == 4
        Rails.logger.warn "Invalid weekly_plan structure: expected 4 weeks, got #{weekly_plan&.length}"
        return payload # Return original if structure is too broken to fix
      end

      unless frequency_per_week.is_a?(Integer) && frequency_per_week > 0
        Rails.logger.warn "Invalid frequency_per_week: #{frequency_per_week}"
        return payload
      end

      fixed_weekly_plan = weekly_plan.map.with_index do |week_data, index|
        actual_week = index + 1
        ideas = week_data["ideas"] || []
        actual_count = ideas.length

        if actual_count != frequency_per_week
          Rails.logger.warn "Week #{actual_week}: expected #{frequency_per_week} ideas, got #{actual_count}"

          # Attempt to fix by duplicating or trimming ideas
          if actual_count < frequency_per_week
            # Duplicate existing ideas to reach target
            while ideas.length < frequency_per_week && ideas.any?
              template_idea = ideas.sample.dup
              # Modify the ID to make it unique
              template_idea["id"] = template_idea["id"]&.gsub(/-i(\d+)-/, "-i#{ideas.length + 1}-")
              template_idea["title"] = "#{template_idea['title']} (Auto-generated #{ideas.length + 1})"
              ideas << template_idea
            end

            # If still not enough, create minimal ideas
            while ideas.length < frequency_per_week
              pillar = [ "C", "R", "E", "A", "S" ].sample
              ideas << {
                "id" => "#{payload['month']&.gsub('-', '')}-#{payload['brand_slug']}-w#{actual_week}-i#{ideas.length + 1}-#{pillar}",
                "title" => "Week #{actual_week} Content #{ideas.length + 1}",
                "hook" => "Engaging hook",
                "description" => "Auto-generated content idea",
                "platform" => "Instagram Reels",
                "pilar" => pillar,
                "recommended_template" => "only_avatars",
                "video_source" => "none"
              }
            end
          elsif actual_count > frequency_per_week
            # Trim excess ideas
            ideas = ideas.take(frequency_per_week)
          end
        end

        week_data.merge("ideas" => ideas)
      end

      fixed_payload = payload.merge("weekly_plan" => fixed_weekly_plan)

      # Log the final distribution
      final_counts = fixed_payload["weekly_plan"].map { |week| week["ideas"]&.length || 0 }
      Rails.logger.info "Weekly distribution validated: #{final_counts.join('-')} (total: #{final_counts.sum})"

      fixed_payload
    end
  end
end
