class BrandSelectionController < ApplicationController
  before_action :authenticate_user!

  def show
    # If user has a current brand, redirect to it
    if current_user.current_brand
      locale = params[:locale] || I18n.locale || I18n.default_locale
      redirect_to "/#{current_user.current_brand.slug}/#{locale}"
    else
      # If user has no brands, redirect to create brand
      locale = params[:locale] || I18n.locale || I18n.default_locale
      redirect_to "/#{locale}/brand/edit"
    end
  end
end
