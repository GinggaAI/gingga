class ApiIntegrationsController < ApplicationController
  protect_from_forgery with: :exception

  # PATCH /api_integrations/:provider
  def update
    form = Settings::ApiTokenForm.new(
      user: current_user,
      brand: current_brand,
      provider: provider_param,
      params: params
    )

    responder.respond_to_update(form.save)
  end

  # POST /api_integrations/:provider/validate
  def validate
    result = validation_service.call

    if result.success?
      handle_successful_validation(result)
    else
      responder.respond_to_validation(result)
    end
  end

  private

  def provider_param
    params[:provider] || params[:id]
  end

  def responder
    @responder ||= Settings::ApiTokenResponder.new(self, provider_param)
  end

  def validation_service
    case provider_param
    when "heygen"
      heygen_validation_service
    when "openai"
      openai_validation_service
    else
      raise ActionController::RoutingError, "Unknown provider: #{provider_param}"
    end
  end

  def heygen_validation_service
    Heygen::ValidateAndSyncService.new(
      user: current_user,
      brand: current_brand,
      voices_count: sanitize_voices_count(params[:voices_count])
    )
  end

  def openai_validation_service
    GinggaOpenAI::ValidateAndUpdateService.new(
      user: current_user,
      brand: current_brand,
      mode: params[:mode] || "production"
    )
  end

  def handle_successful_validation(result)
    case provider_param
    when "heygen"
      responder.respond_to_validation(
        result,
        count: result.data&.[](:synchronized_count),
        message_key: result.data&.[](:message_key)
      )
    else
      responder.respond_to_validation(result)
    end
  end

  def sanitize_voices_count(count)
    count = count&.to_i
    count && count.between?(1, 30) ? count : nil
  end
end
