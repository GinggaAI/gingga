# frozen_string_literal: true

module Creas
  module ContentStructures
    class FrictionEchoes < Base
      def self.config
        {
          name: "Friction Echoes",
          use_for: "Spark debate and provoke discussion - challenge norms or highlight pain points",
          min_scenes: 6,
          max_scenes: 7,
          pillars: %w[R E S],
          content_types: %w[debate controversy challenge]
        }
      end

      def self.template
        <<~TEMPLATE
          • Hook: "X reasons everyone hates ___"
          • Reason #X → #1: [Explanation]
          • Optional CTA
        TEMPLATE
      end
    end
  end
end
