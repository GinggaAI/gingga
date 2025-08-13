class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!, unless: -> { Rails.env.test? }

  # Placeholder for test environment when Devise methods aren't loaded
  def current_user
    if Rails.env.test?
      @test_current_user ||= User.first
    else
      super
    end
  end
end
