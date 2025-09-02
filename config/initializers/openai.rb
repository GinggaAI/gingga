# OpenAI Configuration
module OpenAIConfig
  # Default OpenAI model for the entire application
  # Can be overridden via environment variable OPENAI_MODEL
  DEFAULT_MODEL = ENV.fetch("OPENAI_MODEL", "gpt-4o").freeze

  # Model configuration
  MODELS = {
    "gpt-4o" => {
      name: "gpt-4o",
      description: "Most capable GPT-4 model for complex reasoning and creative tasks"
    },
    "gpt-4o-mini" => {
      name: "gpt-4o-mini",
      description: "Faster and more cost-effective GPT-4 model"
    },
    "gpt-4-turbo" => {
      name: "gpt-4-turbo",
      description: "Previous generation GPT-4 model"
    }
  }.freeze

  # Validate that the configured model is supported
  unless MODELS.key?(DEFAULT_MODEL)
    Rails.logger.warn "OpenAI: Configured model '#{DEFAULT_MODEL}' is not in the supported models list. Supported models: #{MODELS.keys.join(', ')}"
  end

  Rails.logger.info "OpenAI: Using model '#{DEFAULT_MODEL}' for all OpenAI API calls"
end

# Make it available globally
Rails.application.config.openai_model = OpenAIConfig::DEFAULT_MODEL
