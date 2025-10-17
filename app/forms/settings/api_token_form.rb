module Settings
  class ApiTokenForm
    attr_reader :user, :brand, :params, :provider

    def initialize(user:, brand:, provider:, params:)
      @user = user
      @brand = brand
      @provider = provider
      @params = params
    end

    def save
      ApiTokenUpdateService.new(
        user: user,
        brand: brand,
        provider: provider,
        token_value: token_value,
        mode: mode,
        **provider_specific_options
      ).call
    end

    private

    def token_value
      params["#{provider}_api_key"]
    end

    def mode
      params[:mode] || "production"
    end

    def provider_specific_options
      case provider
      when "heygen"
        { group_url: params[:heygen_group_url] }
      else
        {}
      end
    end
  end
end
