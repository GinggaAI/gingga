module Reels
  class OneToThreeVideosCreationService < BaseCreationService
    private

    def setup_template_specific_fields(reel)
      # One to three videos template doesn't use the traditional 3-scene structure
      # It will need fields for video prompts or external video URLs
      
      # For now, we don't add scenes as this template works with video compilation
      # Future: Add fields like video_prompts, video_urls, compilation_style, etc.
    end

    def reel_params
      # Accept additional parameters specific to video compilation template
      base_params = super
      
      # Add video compilation-specific fields when they're implemented
      # base_params.merge(
      #   video_prompts: @params[:video_prompts],
      #   compilation_style: @params[:compilation_style]
      # )
      
      base_params
    end
  end
end