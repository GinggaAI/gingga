class Users::RegistrationsController < Devise::RegistrationsController
  layout "landing"
  skip_before_action :authenticate_user!
end
