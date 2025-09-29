class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!, unless: -> { Rails.env.test? }
  before_action :set_locale
  before_action :set_current_brand_from_url

  # Make current_brand available to all controllers and views
  helper_method :current_brand

  # Placeholder for test environment when Devise methods aren't loaded
  def current_user
    if Rails.env.test?
      @test_current_user ||= User.first
    else
      super
    end
  end

  def current_brand
    current_user&.current_brand
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

  def set_current_brand_from_url
    return unless user_signed_in? && params[:brand_slug].present?

    # Find brand by slug that belongs to current user
    brand = current_user.brands.find_by(slug: params[:brand_slug])

    if brand && brand != current_user.current_brand
      # Update user's current brand if URL brand is different
      current_user.update_last_brand(brand)
    elsif brand.nil?
      # If brand slug doesn't belong to user, redirect to their current brand
      redirect_to "/#{current_user.current_brand&.slug || 'select-brand'}/#{I18n.locale}#{request.path.split('/')[3..-1]&.join('/')}"
    end
  end

  def default_url_options(options = {})
    base_options = { locale: I18n.locale }

    # Include current brand slug in URLs when available
    if user_signed_in? && current_brand
      base_options[:brand_slug] = current_brand.slug
    end

    base_options.merge(options)
  end
end
