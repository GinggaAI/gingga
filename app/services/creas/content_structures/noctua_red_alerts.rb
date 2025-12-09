# frozen_string_literal: true

module Creas
  module ContentStructures
    class NoctuaRedAlerts < Base
      def self.config
        {
          name: "Noctua's Red Alerts",
          use_for: "Warnings about common traps or errors - creates urgency and positions you as protector",
          min_scenes: 6,
          max_scenes: 7,
          pillars: %w[R S A],
          content_types: %w[warning mistake alert]
        }
      end

      def self.template
        <<~TEMPLATE
          • Hook: "Stop. These X ___ will make you ___"
          • Credibility: "I've seen this mistake cause ___"
          • Avoid #X → Alternative: [Fix]
          • Until #1: [Worst one]
          • Optional CTA
        TEMPLATE
      end
    end
  end
end
