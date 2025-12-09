# frozen_string_literal: true

module Creas
  module ContentStructures
    class HeroInnerForge < Base
      def self.config
        {
          name: "The Hero's Inner Forge",
          use_for: "Share transformation story in steps - personal brands, testimonials, or motivational journeys",
          min_scenes: 6,
          max_scenes: 7,
          pillars: %w[A S C],
          content_types: %w[transformation journey motivation]
        }
      end

      def self.template
        <<~TEMPLATE
          • Age X: [Negative situation]
          • Turning point
          • Initial action + result
          • Age Y: [Positive state]
          • Humble reminder close
        TEMPLATE
      end
    end
  end
end
