require "ostruct"

module Reels
  class PresenterService
    def initialize(reel:, template:, current_user:, referrer: nil)
      @reel = reel
      @template = template
      @current_user = current_user
      @referrer = referrer
    end

    def call
      presenter = build_presenter
      view_template = determine_view_template

      return failure_result("Unknown template: #{@template}") unless presenter && view_template

      success_result(
        presenter: presenter,
        view_template: view_template
      )
    rescue StandardError => e
      Rails.logger.error "Presenter setup failed: #{e.message}"
      failure_result("Failed to setup presenter: #{e.message}")
    end

    private

    attr_reader :reel, :template, :current_user

    def build_presenter
      case @template
      when "only_avatars", "avatar_and_video", "one_to_three_videos"
        ReelSceneBasedPresenter.new(reel: @reel, current_user: @current_user, referrer: @referrer)
      when "narration_over_7_images"
        ReelNarrativePresenter.new(reel: @reel, current_user: @current_user, referrer: @referrer)
      end
    end

    def determine_view_template
      case @template
      when "only_avatars", "avatar_and_video", "one_to_three_videos"
        "reels/scene_based"
      when "narration_over_7_images"
        "reels/narrative"
      end
    end

    def success_result(data)
      OpenStruct.new(success?: true, data: data, error: nil)
    end

    def failure_result(error_message)
      OpenStruct.new(success?: false, data: nil, error: error_message)
    end
  end
end
