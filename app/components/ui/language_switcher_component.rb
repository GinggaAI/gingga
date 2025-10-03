# frozen_string_literal: true

class Ui::LanguageSwitcherComponent < ViewComponent::Base
  def initialize(current_locale: I18n.locale, brand: nil, **options)
    @current_locale = current_locale.to_s
    @brand = brand
    @options = options
  end

  private

  attr_reader :current_locale, :brand, :options

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
        # Parse current path to extract brand_slug and path segments
        path_parts = request.path.split("/").reject(&:blank?)

        # If we have brand_slug and current locale, reconstruct with new locale
        if path_parts.length >= 2 && path_parts[1].match?(/^(en|es)$/)
          brand_slug = path_parts[0]
          remaining_path = path_parts[2..-1]&.join("/") || ""
          if remaining_path.empty?
            remaining_path = "/"
          else
            remaining_path = "/#{remaining_path}"
          end
          "/#{brand_slug}/#{locale}#{remaining_path}"
        elsif path_parts.length >= 1 && path_parts[0].match?(/^(en|es)$/)
          # Handle locale-only format: /locale/path
          remaining_path = path_parts[1..-1]&.join("/") || ""
          if remaining_path.empty?
            remaining_path = "/"
          else
            remaining_path = "/#{remaining_path}"
          end

          # Try to include current brand if available
          current_brand_slug = brand&.slug || (respond_to?(:current_brand) && current_brand&.slug)
          if current_brand_slug
            "/#{current_brand_slug}/#{locale}#{remaining_path}"
          else
            "/#{locale}#{remaining_path}"
          end
        else
          # Fallback: try to include current brand if available
          current_brand_slug = brand&.slug || (respond_to?(:current_brand) && current_brand&.slug)
          if current_brand_slug
            "/#{current_brand_slug}/#{locale}"
          else
            "/#{locale}/"
          end
        end
      rescue StandardError => e
        Rails.logger.warn "LanguageSwitcherComponent: Failed to generate path for locale #{locale}: #{e.message}"
        # Fallback if path processing fails
        current_brand_slug = brand&.slug || (respond_to?(:current_brand) && current_brand&.slug)
        if current_brand_slug
          "/#{current_brand_slug}/#{locale}"
        else
          "/#{locale}/"
        end
      end
    else
      # Fallback for tests without request context
      current_brand_slug = brand&.slug || (respond_to?(:current_brand) && current_brand&.slug)
      if current_brand_slug
        "/#{current_brand_slug}/#{locale}"
      else
        "/#{locale}/"
      end
    end
  end
end
