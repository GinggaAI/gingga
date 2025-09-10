module Reels
  class OnlyAvatarsCreationService < BaseCreationService
    private

    def setup_template_specific_fields(reel)
      # Only avatars template requires exactly 3 scenes
      return if reel.reel_scenes.any? # Don't add if scenes already exist

      3.times do |i|
        reel.reel_scenes.build(
          scene_number: i + 1,
          avatar_id: nil,
          voice_id: nil,
          script: nil,
          video_type: "avatar"
        )
      end
    end
  end
end
