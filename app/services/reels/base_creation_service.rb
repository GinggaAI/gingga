module Reels
  class BaseCreationService
    def initialize(user:, template: nil, params: nil)
      @user = user
      @template = template
      @params = params
    end

    def initialize_reel
      reel = @user.reels.build(template: @template, status: "draft")
      setup_template_specific_fields(reel)

      # Save the reel so it can have associated scenes created
      if reel.save
        success_result(reel)
      else
        failure_result(I18n.t("planning.errors.failed_to_initialize_reel_with_error", error: reel.errors.full_messages.join(", ")), reel)
      end
    end

    def call
      reel = @user.reels.build(reel_params)
      setup_template_specific_fields(reel) if reel.new_record?

      if reel.save
        trigger_video_generation(reel)
        success_result(reel)
      else
        failure_result(I18n.t("planning.errors.validation_failed"), reel)
      end
    end

    private

    def reel_params
      @params.merge(status: "draft")
    end

    def setup_template_specific_fields(reel)
      # Override in subclasses
    end

    def trigger_video_generation(reel)
      return unless should_generate_video?(reel)
      return unless reel.ready_for_generation?


      generation_result = Heygen::GenerateVideoService.new(@user, reel).call

      if generation_result[:success]
        # Schedule status checking job
        CheckVideoStatusJob.set(wait: 30.seconds).perform_later(reel.id)
      else
        Rails.logger.error "❌ Video generation failed for reel #{reel.id}: #{generation_result[:error]}"
        reel.update!(status: "failed")
      end
    rescue StandardError => e
      Rails.logger.error "🚨 Error triggering video generation for reel #{reel.id}: #{e.message}"
      reel.update!(status: "failed")
    end

    def should_generate_video?(reel)
      # Only generate videos for templates that support HeyGen integration
      reel.template.in?(%w[only_avatars avatar_and_video])
    end

    def success_result(reel)
      { success: true, reel: reel, error: nil }
    end

    def failure_result(error_message, reel = nil)
      { success: false, reel: reel, error: error_message }
    end
  end
end
