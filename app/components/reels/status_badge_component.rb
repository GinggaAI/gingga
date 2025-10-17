# frozen_string_literal: true

module Reels
  class StatusBadgeComponent < ViewComponent::Base
    # Whitelisted CSS classes for security - only predefined values allowed
    STATUS_BADGE_CLASSES = {
      "draft" => %w[status-badge status-badge--draft],
      "processing" => %w[status-badge status-badge--processing],
      "completed" => %w[status-badge status-badge--completed],
      "failed" => %w[status-badge status-badge--failed]
    }.freeze

    def initialize(status:, icon: nil)
      @status = status
      @icon = icon
    end

    def css_classes
      # Use whitelisted hash lookup for security - prevents any user input injection
      # Returns Array of CSS class strings for safe attribute building
      STATUS_BADGE_CLASSES.fetch(@status.to_s.strip, STATUS_BADGE_CLASSES["draft"])
    end

    def icon
      @icon
    end
  end
end
