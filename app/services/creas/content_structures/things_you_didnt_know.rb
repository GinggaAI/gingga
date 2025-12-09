# frozen_string_literal: true

module Creas
  module ContentStructures
    class ThingsYouDidntKnow < Base
      def self.config
        {
          name: "Things You Didn't Know",
          use_for: "Create 'aha' moments - teach fast in punchy, surprising way",
          min_scenes: 6,
          max_scenes: 7,
          pillars: %w[C E A],
          content_types: %w[learning surprise education]
        }
      end

      def self.template
        <<~TEMPLATE
          • Hook: "X things you didn't know about ___"
          • List #X → #1: [Fact]
          • Optional CTA
        TEMPLATE
      end
    end
  end
end
