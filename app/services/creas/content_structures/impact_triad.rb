# frozen_string_literal: true

module Creas
  module ContentStructures
    class ImpactTriad < Base
      def self.config
        {
          name: "Impact Triad",
          use_for: "Fast, impactful, highly shareable - top 3 recommendations for actions, apps, routines, or tips",
          min_scenes: 6,
          max_scenes: 6,
          pillars: %w[C E A],
          content_types: %w[list recommendation tip]
        }
      end

      def self.template
        <<~TEMPLATE
          • Hook: "Top 3 ___ for ___"
          • #3: [Tip] + [Why it works]
          • #2: Optional joke + real tip
          • #1: [Most important] + [Expected result]
          • Optional CTA
        TEMPLATE
      end
    end
  end
end
