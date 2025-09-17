module Reels
  class OnlyAvatarsCreationService < BaseCreationService
    private

    def setup_template_specific_fields(reel)
      # Only avatars template requires exactly 3 scenes
      # Don't create default empty scenes during initialization - they will be created
      # by SmartPlanningPreloadService or user will fill them manually later
      # Creating empty scenes with nil values would fail validation
    end
  end
end
