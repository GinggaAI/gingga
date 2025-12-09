# frozen_string_literal: true

module Creas
  module ContentStructures
    class AwakeningData < Base
      def self.config
        {
          name: "Awakening Data",
          use_for: "Educate, shift perspective, or introduce new logic with authority",
          min_scenes: 6,
          max_scenes: 7,
          pillars: %w[C E A],
          content_types: %w[education data insight]
        }
      end

      def self.template
        <<~TEMPLATE
          • Hook: "X [adjective] facts about ___"
          • List #X → #1: [Fact]
          • Optional CTA
        TEMPLATE
      end
    end
  end
end
