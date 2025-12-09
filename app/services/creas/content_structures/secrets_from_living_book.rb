# frozen_string_literal: true

module Creas
  module ContentStructures
    class SecretsFromLivingBook < Base
      def self.config
        {
          name: "Secrets from the Living Book",
          use_for: "Share exclusive insights or insider knowledge - sparks curiosity and saves time",
          min_scenes: 6,
          max_scenes: 7,
          pillars: %w[C E A],
          content_types: %w[secret insight insider]
        }
      end

      def self.template
        <<~TEMPLATE
          • Hook: "X secrets to ___ nobody talks about"
          • Brief authority
          • Secret #X → #1: [Explanation]
          • Optional CTA
        TEMPLATE
      end
    end
  end
end
