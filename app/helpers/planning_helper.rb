module PlanningHelper
  # Maps objectives to their recommended themes
  OBJECTIVE_THEMES = {
    "awareness" => [
      "Brand Story & Origin",
      "Product/Service Showcase",
      "Industry Trends",
      "Community Spotlights"
    ],
    "engagement" => [
      "Q&A / Behind the Scenes",
      "User-Generated Content",
      "Interactive Polls & Challenges",
      "Community Highlights"
    ],
    "sales" => [
      "Product Benefits & Use Cases",
      "Comparisons / Alternatives",
      "Social Proof",
      "Offers & Promotions"
    ],
    "community" => [
      "Educational / How-to Tips",
      "Advanced Product Use Cases",
      "Customer Appreciation",
      "Referral & Loyalty Programs"
    ]
  }.freeze

  # Available reel generation templates with their descriptions
  REEL_TEMPLATES = {
    "only_avatars" => "Only Avatars - AI-generated characters speaking directly",
    "avatar_and_video" => "Avatar + Video - Combine AI avatars with background video",
    "narration_over_7_images" => "Narration over Images - Voiceover with 7 rotating images",
    "remix" => "Remix - Repurpose existing content with new format",
    "one_to_three_videos" => "Multiple Videos - Combine 1-3 video clips"
  }.freeze

  # Returns recommended themes for a given objective
  def recommended_themes_for(objective)
    OBJECTIVE_THEMES[objective.to_s] || []
  end

  # Returns all available templates with their descriptions
  def available_templates
    REEL_TEMPLATES
  end

  # Returns all available objectives with their labels
  def strategy_objectives
    [
      [ "Awareness - Build brand recognition", "awareness" ],
      [ "Engagement - Foster community interaction", "engagement" ],
      [ "Sales - Drive conversions and revenue", "sales" ],
      [ "Community - Strengthen customer relationships", "community" ]
    ]
  end
end
