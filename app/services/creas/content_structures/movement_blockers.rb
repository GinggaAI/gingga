# frozen_string_literal: true

module Creas
  module ContentStructures
    class MovementBlockers < Base
      def self.config
        {
          name: "Movement Blockers",
          use_for: "Help viewers improve by avoiding mistakes - humanizes you while educating",
          min_scenes: 6,
          max_scenes: 7,
          pillars: %w[R E A S],
          content_types: %w[mistake improvement education]
        }
      end

      def self.template
        <<~TEMPLATE
          • Hook: "Are you making these X mistakes when ___?"
          • Authority: "I've done this for X years"
          • Mistake #X → Fix
          • Mistake #1: [Most critical one]
          • Optional CTA
        TEMPLATE
      end
    end
  end
end
