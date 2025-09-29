class SettingsPresenter
  def initialize(user, brand = nil, params = {})
    @user = user
    @brand = brand || user.current_brand
    @params = params
    @flash = params[:flash] || {}
  end

  # HeyGen API Token Methods
  def heygen_token
    @heygen_token ||= @brand&.active_token_for("heygen")
  end

  def heygen_token_value
    heygen_token&.encrypted_token if heygen_token&.encrypted_token.present?
  end

  def heygen_group_url_value
    heygen_token&.group_url if heygen_token&.group_url.present?
  end

  def heygen_configured?
    heygen_token&.is_valid || false
  end

  def heygen_configuration_status
    if heygen_configured?
      "Configured"
    else
      "Not configured"
    end
  end

  def heygen_status_class
    if heygen_configured?
      "inline-flex items-center rounded-full border text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 border-transparent bg-green-100 text-green-700 px-2.5 py-0.5"
    else
      "inline-flex items-center rounded-full border text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 border-transparent bg-secondary text-secondary-foreground px-2.5 py-0.5 hover:bg-secondary/80"
    end
  end

  # Group URL Field Logic
  def show_group_url_field?
    true  # Always show group URL field alongside API key field
  end

  # Validation Button Logic
  def show_validate_button?
    heygen_configured?
  end

  def show_disabled_validate_button?
    !heygen_configured?
  end

  def validate_button_class
    "inline-flex items-center justify-center gap-2 whitespace-nowrap text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 h-10 px-4 py-2 text-white rounded-xl [&_svg]:pointer-events-none [&_svg]:size-4 [&_svg]:shrink-0 bg-[#3AC8FF] hover:bg-[#3AC8FF]/90 border-0"
  end

  def disabled_validate_button_class
    "inline-flex items-center justify-center gap-2 whitespace-nowrap text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 h-10 px-4 py-2 text-white rounded-xl [&_svg]:pointer-events-none [&_svg]:size-4 [&_svg]:shrink-0 bg-gray-400"
  end

  def disabled_validate_button_title
    I18n.t("settings.heygen.disabled_validate_button_title")
  end

  # Flash Messages
  def show_notice?
    @flash[:notice].present?
  end

  def show_alert?
    @flash[:alert].present?
  end

  def notice_message
    @flash[:notice]
  end

  def alert_message
    @flash[:alert]
  end

  # API Integrations Overview Stats
  def active_connections_count
    @brand&.api_tokens&.valid_tokens&.count || 0
  end

  def available_services_count
    # Could be made dynamic based on configured services
    3
  end

  def test_mode_count
    @brand&.api_tokens&.test_mode&.count || 0
  end

  private

  attr_reader :user, :params, :flash
end
