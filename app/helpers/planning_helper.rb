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

  # Returns recommended themes for a given objective
  def recommended_themes_for(objective)
    OBJECTIVE_THEMES[objective.to_s] || []
  end

  # Renders a theme chip component
  def theme_chip(theme, selected: false, custom: false, removable: false)
    css_classes = [
      "inline-flex", "items-center", "gap-2", "px-3", "py-1.5", "rounded-full",
      "text-sm", "font-medium", "cursor-pointer", "transition-colors",
      "border", "select-none"
    ]

    if selected
      css_classes += [ "bg-blue-100", "text-blue-800", "border-blue-300" ]
    else
      css_classes += [ "bg-gray-100", "text-gray-600", "border-gray-300", "hover:bg-gray-200" ]
    end

    if custom
      css_classes += [ "bg-green-50", "text-green-700", "border-green-200" ] if selected
    end

    content_tag(:div, class: css_classes.join(" "), data: { theme: theme, selected: selected }) do
      chip_content = []

      # Add checkmark for selected themes
      if selected
        chip_content << content_tag(:span, "✓", class: "text-xs")
      end

      chip_content << content_tag(:span, theme)

      # Add remove button for custom themes
      if removable && custom
        chip_content << content_tag(:button, "×",
          class: "ml-1 text-xs hover:text-red-600",
          type: "button",
          data: { action: "remove-theme" }
        )
      end

      safe_join(chip_content)
    end
  end

  # Renders the add custom theme chip
  def add_custom_theme_chip
    content_tag(:div,
      class: "inline-flex items-center gap-2 px-3 py-1.5 rounded-full text-sm font-medium cursor-pointer transition-colors border border-dashed border-gray-400 text-gray-500 hover:border-gray-600 hover:text-gray-700",
      id: "add-custom-theme-chip",
      data: { action: "add-custom-theme" }
    ) do
      content_tag(:span, "+ Add Custom Theme")
    end
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
