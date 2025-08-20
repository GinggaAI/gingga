class Users::PasswordsController < Devise::PasswordsController
  layout "landing"
  skip_before_action :authenticate_user!
end
