# frozen_string_literal: true

module Creas
  module ContentStructures
    class NoctuaHiddenTruths < Base
      def self.config
        {
          name: "Noctua's Hidden Truths",
          use_for: "Drop surprising or little-known facts - positions you as trusted knowledge source",
          min_scenes: 6,
          max_scenes: 7,
          pillars: %w[C E A],
          content_types: %w[fact surprise knowledge]
        }
      end

      def self.template
        <<~TEMPLATE
          • Hook: "X [adjective] facts about ___"
          • Fact #X → #1: [Fact] + [Context]
          • Optional CTA
        TEMPLATE
      end
    end
  end
end
