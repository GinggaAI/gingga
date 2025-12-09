# frozen_string_literal: true

module Creas
  module ContentStructures
    class VoxaRadiantRankings < Base
      def self.config
        {
          name: "Voxa's Radiant Rankings",
          use_for: "Lists, rankings, 'top X' content - establishes authority and delivers quick value",
          min_scenes: 6,
          max_scenes: 7,
          pillars: %w[C E A],
          content_types: %w[list ranking recommendation]
        }
      end

      def self.template
        <<~TEMPLATE
          • Hook: "Top X ___ you need to try now"
          • Authority: "I've tested X ___..."
          • Countdown #X → #1: [Item] + [Benefit] + [Use case]
          • Closing line: "My favorite is ___ because ___"
          • Optional CTA
        TEMPLATE
      end
    end
  end
end
