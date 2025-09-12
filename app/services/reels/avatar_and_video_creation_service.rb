module Reels
  class AvatarAndVideoCreationService < BaseCreationService
    private

    def setup_template_specific_fields(reel)
      # Avatar and video template requires exactly 3 scenes (mix of avatar and video)
      return if reel.reel_scenes.any? # Don't add if scenes already exist

      3.times do |i|
        reel.reel_scenes.build(
          scene_number: i + 1,
          avatar_id: nil,
          voice_id: nil,
          script: nil,
          video_type: nil
        )
      end
    end
  end
end
