# frozen_string_literal: true

module Creas
  module ContentStructures
    class SaguiInfiniteLoop < Base
      def self.config
        {
          name: "Sagui's Infinite Loop",
          use_for: "Break common myths or show cause-and-effect patterns - controversial truths or storytelling with twist",
          min_scenes: 6,
          max_scenes: 7,
          pillars: %w[E R S],
          content_types: %w[myth pattern story]
        }
      end

      def self.template
        <<~TEMPLATE
          • Hook: "This will keep you ___ forever: ___"
          • Exposition
          • Consequence #1, #2
          • Loop close: "That's why..."
          • Optional CTA
        TEMPLATE
      end
    end
  end
end
