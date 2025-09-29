class ApiTokenUpdateService
  def initialize(user:, brand:, provider:, token_value:, mode: "production", **options)
    @user = user
    @brand = brand
    @provider = provider
    @token_value = token_value
    @mode = mode
    @options = options
  end

  def call
    return failure_result("Token value is required") if @token_value.blank?
    return failure_result("Brand is required") unless @brand

    api_token = find_or_initialize_token
    update_token_attributes(api_token)

    if api_token.save
      success_result(api_token: api_token)
    else
      failure_result("Failed to save API token: #{api_token.errors.full_messages.join(', ')}")
    end
  rescue StandardError => e
    failure_result("Error updating API token: #{e.message}")
  end

  private

  def find_or_initialize_token
    @brand.api_tokens.find_or_initialize_by(
      user: @user,
      provider: @provider,
      mode: @mode
    )
  end

  def update_token_attributes(api_token)
    api_token.encrypted_token = @token_value

    # Handle provider-specific options
    case @provider
    when "heygen"
      api_token.group_url = @options[:group_url].present? ? @options[:group_url] : nil
    end
  end

  def success_result(api_token:)
    OpenStruct.new(success?: true, data: { api_token: api_token }, error: nil)
  end

  def failure_result(error_message)
    OpenStruct.new(success?: false, data: nil, error: error_message)
  end
end
