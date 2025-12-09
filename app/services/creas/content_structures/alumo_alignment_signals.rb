# frozen_string_literal: true

module Creas
  module ContentStructures
    class AlumoAlignmentSignals < Base
      def self.config
        {
          name: "Alumo's Alignment Signals",
          use_for: "Help audience self-identify or validate their journey - builds empathy and connection",
          min_scenes: 6,
          max_scenes: 7,
          pillars: %w[A S R],
          content_types: %w[validation signs identification]
        }
      end

      def self.template
        <<~TEMPLATE
          • Hook: "Here are X signs that ___"
          • Sign #X: [Description] + [What it means]
          • Sign #1: [Most critical]
          • Optional CTA
        TEMPLATE
      end
    end
  end
end
