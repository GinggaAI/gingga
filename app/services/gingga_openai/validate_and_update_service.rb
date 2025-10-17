module GinggaOpenAI
  class ValidateAndUpdateService
    Result = Struct.new(:success?, :data, :error, keyword_init: true)

    def initialize(user:, brand:, mode: "production")
      @user = user
      @brand = brand
      @mode = mode
    end

    def call
      token = find_token
      return failure_result("No API token found. Please save an OpenAI API key first.") unless token

      validation_result = validate_token(token)

      if validation_result[:valid]
        token.update(is_valid: true)
        success_result
      else
        token.update(is_valid: false)
        failure_result(validation_result[:error] || "Token validation failed")
      end
    rescue StandardError => e
      failure_result("Validation error: #{e.message}")
    end

    private

    attr_reader :user, :brand, :mode

    def find_token
      @brand.api_tokens.find_by(provider: "openai", mode: @mode)
    end

    def validate_token(token)
      GinggaOpenAI::ValidateKeyService.new(
        token: token.encrypted_token,
        mode: token.mode
      ).call
    end

    def success_result
      Result.new(
        success?: true,
        data: { message: "OpenAI API key validated successfully" },
        error: nil
      )
    end

    def failure_result(error_message)
      Result.new(
        success?: false,
        data: nil,
        error: error_message
      )
    end
  end
end
