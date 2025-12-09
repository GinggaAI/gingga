# frozen_string_literal: true

module Creas
  module ContentStructures
    class SaguiRationale < Base
      def self.config
        {
          name: "Sagui's Rationale",
          use_for: "Classic persuasion format - convince someone of something, simple and structured",
          min_scenes: 6,
          max_scenes: 7,
          pillars: %w[C E A],
          content_types: %w[persuasion reasoning argument]
        }
      end

      def self.template
        <<~TEMPLATE
          • Hook: "X reasons why ___"
          • List #X → #1: [Reason]
          • Optional CTA
        TEMPLATE
      end
    end
  end
end
