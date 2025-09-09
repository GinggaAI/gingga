class SettingsController < ApplicationController
  # Ensure CSRF protection is enabled
  protect_from_forgery with: :exception
  def show
    @presenter = SettingsPresenter.new(current_user, {
      flash: flash
    })
  end

  def update
    result = ApiTokenUpdateService.new(
      user: current_user,
      provider: "heygen",
      token_value: params[:heygen_api_key],
      mode: params[:mode] || "production",
      group_url: params[:heygen_group_url]
    ).call

    if result.success?
      redirect_to settings_path, notice: t("settings.heygen.save_success"), allow_other_host: false
    else
      redirect_to settings_path, alert: t("settings.heygen.save_failed", error: result.error), allow_other_host: false
    end
  end

  def validate_heygen_api
    voices_count = params[:voices_count]&.to_i
    voices_count = nil unless voices_count && voices_count.between?(1, 30)
    
    result = Heygen::ValidateAndSyncService.new(user: current_user, voices_count: voices_count).call

    if result.success?
      count = result.data[:synchronized_count]
      message_key = result.data[:message_key]
      redirect_to settings_path, notice: t(message_key, count: count), allow_other_host: false
    else
      redirect_to settings_path, alert: t("settings.heygen.validation_failed", error: result.error), allow_other_host: false
    end
  end
end
