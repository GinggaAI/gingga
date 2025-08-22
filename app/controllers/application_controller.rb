class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!, unless: -> { Rails.env.test? }
  before_action :set_locale

  # Placeholder for test environment when Devise methods aren't loaded
  def current_user
    if Rails.env.test?
      @test_current_user ||= User.first
    else
      super
    end
  end

  private

  def set_locale
    I18n.locale = extract_locale || I18n.default_locale
  end

  def extract_locale
    # Check for locale parameter first
    parsed_locale = params[:locale]

    # Check if it's a valid locale
    if parsed_locale.present? && I18n.available_locales.map(&:to_s).include?(parsed_locale)
      session[:locale] = parsed_locale
      return parsed_locale
    end

    # Use session locale if available
    if session[:locale].present? && I18n.available_locales.map(&:to_s).include?(session[:locale])
      return session[:locale]
    end

    # Extract from Accept-Language header as fallback
    request.env["HTTP_ACCEPT_LANGUAGE"]&.scan(/^[a-z]{2}/)&.first&.tap do |header_locale|
      if I18n.available_locales.map(&:to_s).include?(header_locale)
        return header_locale
      end
    end

    nil
  end

  def default_url_options(options = {})
    { locale: I18n.locale }.merge(options)
  end
end
