# frozen_string_literal: true

module Creas
  module ContentStructures
    class ChroniclesInMotion < Base
      def self.config
        {
          name: "Chronicles in Motion",
          use_for: "Showcase milestones or legendary moments - brand storytelling and historical inspiration",
          min_scenes: 6,
          max_scenes: 7,
          pillars: %w[C S A],
          content_types: %w[story milestone history]
        }
      end

      def self.template
        <<~TEMPLATE
          • Hook: "X times ___ did ___"
          • Event #X → #1: [Moment] + [Context]
          • Optional CTA
        TEMPLATE
      end
    end
  end
end
