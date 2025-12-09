# frozen_string_literal: true

module Creas
  module ContentStructures
    class ShadowsTriad < Base
      def self.config
        {
          name: "Shadows Triad",
          use_for: "Use negativity as hook - 'what to avoid' or 'worst of' content",
          min_scenes: 6,
          max_scenes: 6,
          pillars: %w[R S A],
          content_types: %w[warning avoid worst]
        }
      end

      def self.template
        <<~TEMPLATE
          • Hook: "Top 3 worst ___ blocking your ___"
          • #3: [What it is] + [Why it's bad]
          • #2: Optional joke + real issue
          • #1: [Worst one] + [Consequence]
          • Optional CTA
        TEMPLATE
      end
    end
  end
end
