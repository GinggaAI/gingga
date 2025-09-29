module Ui
  class SidebarBrandSwitcherComponent < ViewComponent::Base
    def initialize(current_user:, current_brand: nil)
      @current_user = current_user
      @current_brand = current_brand || current_user.current_brand
    end

    private

    attr_reader :current_user, :current_brand

    def user_brands
      @user_brands ||= current_user.brands.order(:created_at)
    end

    def has_brands?
      user_brands.any?
    end

    def current_brand_name
      current_brand&.name || t('brands.no_brand_selected')
    end

    def show_create_brand_cta?
      !has_brands?
    end
  end
end