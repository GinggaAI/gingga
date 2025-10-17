class SettingsController < ApplicationController
  # Ensure CSRF protection is enabled
  protect_from_forgery with: :exception

  def show
    @presenter = SettingsPresenter.new(current_user, current_brand, {
      flash: flash
    })
  end
end
