class Users::SessionsController < Devise::SessionsController
  layout "landing"
  skip_before_action :authenticate_user!

  protected

  # Override the default after_sign_in_path to redirect to the brand page
  def after_sign_in_path_for(resource)
    brand_path
  end

  # Override the default after_sign_out_path to redirect to the sign-in page
  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end
end
