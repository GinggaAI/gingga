class BrandSwitchingController < ApplicationController
  before_action :authenticate_user!

  def create
    result = Brands::SelectionService.new(
      user: current_user,
      brand_id: params[:brand_id]
    ).call

    if result[:success]
      render json: { success: true, brand: result[:data][:brand].slice(:id, :name, :slug) }
    else
      render json: { success: false, error: result[:error] }, status: :unprocessable_entity
    end
  end
end