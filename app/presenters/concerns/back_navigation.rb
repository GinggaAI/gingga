module BackNavigation
  def back_path
    return root_path unless referrer

    referer_uri = URI.parse(referrer)
    referer_path = referer_uri.path

    # Check if referrer is from auto_creation or planning
    if referer_path.include?("/auto_creation")
      auto_creation_path
    elsif referer_path.include?("/planning")
      planning_path
    else
      root_path
    end
  rescue URI::InvalidURIError
    root_path
  end

  private

  def root_path
    Rails.application.routes.url_helpers.root_path(
      brand_slug: current_brand.slug,
      locale: I18n.locale
    )
  end

  def auto_creation_path
    Rails.application.routes.url_helpers.auto_creation_path(
      brand_slug: current_brand.slug,
      locale: I18n.locale
    )
  end

  def planning_path
    Rails.application.routes.url_helpers.planning_path(
      brand_slug: current_brand.slug,
      locale: I18n.locale
    )
  end

  def current_brand
    current_user&.current_brand
  end
end
