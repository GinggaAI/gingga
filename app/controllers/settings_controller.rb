class SettingsController < ApplicationController
  def show
    @heygen_token = current_user.active_token_for("heygen")
  end

  def update
    token_value = params[:heygen_api_key]
    mode = params[:mode] || "production"
    
    if token_value.present?
      # Find or create the API token
      api_token = current_user.api_tokens.find_or_initialize_by(
        provider: "heygen",
        mode: mode
      )
      
      api_token.encrypted_token = token_value
      
      if api_token.save
        redirect_to settings_path, notice: t("settings.heygen.save_success")
      else
        redirect_to settings_path, alert: t("settings.heygen.save_failed", error: api_token.errors.full_messages.join(", "))
      end
    else
      redirect_to settings_path, alert: t("settings.heygen.empty_token")
    end
  end

  def validate_heygen_api
    result = Heygen::SynchronizeAvatarsService.new(user: current_user).call

    if result.success?
      redirect_to settings_path, notice: t("settings.heygen.validation_success", count: result.data[:synchronized_count])
    else
      redirect_to settings_path, alert: t("settings.heygen.validation_failed", error: result.error)
    end
  end
end
