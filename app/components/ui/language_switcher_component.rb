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
        # Parse current path to extract brand_slug and path
        current_path = request.path

        # Handle brand_slug/locale/path format: /brand-slug/locale/path
        if current_path.match(%r{^/([^/]+)/(en|es)(/.*)?$})
          brand_slug = $1
          current_locale = $2
          path_after_locale = $3 || ""

          # Reconstruct URL with new locale: /brand-slug/new-locale/path
          "/#{brand_slug}/#{locale}#{path_after_locale}"
        elsif current_path.match(%r{^/(en|es)(/.*)?$})
          # Handle locale-only format: /locale/path (fallback)
          path_after_locale = $2 || ""
          "/#{locale}#{path_after_locale}"
        else
          # Fallback for unknown format
          "/#{locale}/"
        end
      rescue StandardError => e
        Rails.logger.warn "LanguageSwitcherComponent: Failed to generate path for locale #{locale}: #{e.message}"
        # Fallback if path processing fails
        "/#{locale}/"
      end
    else
      # Fallback for tests without request context
      "/#{locale}/"
    end
  end
end
