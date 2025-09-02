# frozen_string_literal: true

class Ui::LanguageSwitcherComponent < ViewComponent::Base
  def initialize(current_locale: I18n.locale, **options)
    @current_locale = current_locale.to_s
    @options = options
  end

  private

  attr_reader :current_locale, :options

  def available_locales
    I18n.available_locales.map do |locale|
      {
        code: locale.to_s,
        name: locale_name(locale),
        current: locale.to_s == current_locale
      }
    end
  end

  def locale_name(locale)
    case locale.to_s
    when "en"
      t("nav.english")
    when "es"
      t("nav.spanish")
    else
      locale.to_s.humanize
    end
  end

  def switch_locale_path(locale)
    if respond_to?(:request) && request.present?
      begin
        # Try to maintain current path with locale switch
        current_path = request.path
        # Remove existing locale prefix if present
        current_path = current_path.sub(%r{^/(en|es)/?}, "/")
        # Remove leading slash for processing
        current_path = current_path.sub(%r{^/}, "")

        # Always include locale prefix to ensure session is set correctly
        if current_path.empty?
          locale == I18n.default_locale.to_s ? "/" : "/#{locale}/"
        else
          "/#{locale}/#{current_path}"
        end
      rescue StandardError => e
        Rails.logger.warn "LanguageSwitcherComponent: Failed to generate path for locale #{locale}: #{e.message}"
        # Fallback if path processing fails
        locale == I18n.default_locale.to_s ? "/" : "/#{locale}/"
      end
    else
      # Fallback for tests without request context
      locale == I18n.default_locale.to_s ? "/" : "/#{locale}/"
    end
  end
end
