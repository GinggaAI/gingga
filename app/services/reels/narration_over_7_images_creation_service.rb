module Reels
  class NarrationOver7ImagesCreationService < BaseCreationService
    private

    def setup_template_specific_fields(reel)
      # Narration over 7 images template doesn't require scenes
      # Instead it will need fields for image prompts and narration
      # These fields can be added to the reel model or stored in a JSON field

      # For now, we don't add scenes as this template works differently
      # Future: Add fields like narration_text, image_prompts, etc.
    end

    def reel_params
      # Accept additional parameters specific to narration template
      base_params = super

      # Add narration-specific fields when they're implemented
      # base_params.merge(
      #   narration_text: @params[:narration_text],
      #   image_themes: @params[:image_themes]
      # )

      base_params
    end
  end
end
