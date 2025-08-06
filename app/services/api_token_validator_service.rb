class ApiTokenValidatorService
  def initialize(provider:, token:, mode:)
    @provider = provider
    @token = token
    @mode = mode
  end

  def call
    validator_class = "#{@provider.capitalize}::ValidateKeyService".constantize
    validator_class.new(token: @token, mode: @mode).call
  rescue NameError
    { valid: false, error: "Unsupported provider: #{@provider}" }
  rescue StandardError => e
    { valid: false, error: "Validation failed: #{e.message}" }
  end

  private

  attr_reader :provider, :token, :mode
end
