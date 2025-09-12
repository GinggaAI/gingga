class Planning::ContentDetailsController < ApplicationController
  before_action :authenticate_user!

  # Single Responsibility: Content Details AJAX rendering
  # GET /planning/content_details
  def show
    result = Planning::ContentDetailsService.new(
      content_data: params[:content_data],
      user: current_user
    ).call

    if result.success?
      render json: { html: result.html }
    else
      render json: { error: result.error_message },
             status: result.status_code
    end
  end
end
