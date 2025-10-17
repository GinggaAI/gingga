class SettingsController < ApplicationController
  # Ensure CSRF protection is enabled
  protect_from_forgery with: :exception

  def show
    @presenter = SettingsPresenter.new(current_user, current_brand, {
      flash: flash
    })
  end

  def update
    result = ApiTokenUpdateService.new(
      user: current_user,
      brand: current_brand,
      provider: "heygen",
      token_value: params[:heygen_api_key],
      mode: params[:mode] || "production",
      group_url: params[:heygen_group_url]
    ).call

    handle_update_result(result, "heygen")
  end

  def update_openai
    result = ApiTokenUpdateService.new(
      user: current_user,
      brand: current_brand,
      provider: "openai",
      token_value: params[:openai_api_key],
      mode: params[:mode] || "production"
    ).call

    handle_update_result(result, "openai")
  end

  def validate_heygen_api
    voices_count = params[:voices_count]&.to_i
    voices_count = nil unless voices_count && voices_count.between?(1, 30)

    result = Heygen::ValidateAndSyncService.new(
      user: current_user,
      brand: current_brand,
      voices_count: voices_count
    ).call

    if result.success?
      count = result.data[:synchronized_count]
      message_key = result.data[:message_key]
      redirect_to settings_path, notice: t(message_key, count: count), allow_other_host: false
    else
      redirect_to settings_path, alert: t("settings.heygen.validation_failed", error: result.error), allow_other_host: false
    end
  end

  def validate_openai_api
    result = GinggaOpenAI::ValidateAndUpdateService.new(
      user: current_user,
      brand: current_brand,
      mode: params[:mode] || "production"
    ).call

    if result.success?
      redirect_to settings_path, notice: t("settings.openai.validation_success"), allow_other_host: false
    else
      redirect_to settings_path, alert: t("settings.openai.validation_failed", error: result.error), allow_other_host: false
    end
  end

  private

  def handle_update_result(result, provider)
    if result.success?
      redirect_to settings_path, notice: t("settings.#{provider}.save_success"), allow_other_host: false
    else
      redirect_to settings_path, alert: t("settings.#{provider}.save_failed", error: result.error), allow_other_host: false
    end
  end
end
