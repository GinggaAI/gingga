class BrandsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_brand, only: [ :show, :edit, :update ]

  def show
    redirect_to edit_brand_path
  end

  def edit
    @brand = current_user_brand || current_user.brands.build
    @brands = current_user.brands.order(:created_at)
    @presenter = BrandPresenter.new(@brand, {
      notice: flash[:notice],
      brands_collection: @brands
    })
  end

  def update
    @brand = current_user_brand || current_user.brands.create

    if @brand.update(brand_params)
      redirect_to edit_brand_path, notice: "Brand profile updated successfully!"
    else
      @brands = current_user.brands.order(:created_at)
      @presenter = BrandPresenter.new(@brand, {
        notice: flash[:notice],
        brands_collection: @brands
      })
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_brand
    @brand = current_user_brand
  end

  def current_user_brand
    # Get the primary/first brand or the brand specified in params
    if params[:brand_id].present?
      current_user.brands.find(params[:brand_id])
    else
      current_user.brands.first
    end
  end

  def brand_params
    params.require(:brand).permit(
      :name, :slug, :industry, :value_proposition, :mission, :voice,
      :content_language, :account_language, :subtitle_languages, :dub_languages,
      :region, :timezone, :guardrails, :resources,
      # Virtual attributes for form handling
      :tone_no_go_list, :banned_words_list, :claims_rules_text,
      :kling_enabled, :stock_enabled, :budget_enabled, :editing_enabled, :ai_avatars_enabled, :podcast_clips_enabled,
      # Nested attributes
      audiences_attributes: [ :id, :name, :demographic_profile, :interests, :digital_behavior, :_destroy ],
      products_attributes: [ :id, :name, :description, :pricing_info, :url, :_destroy ],
      brand_channels_attributes: [ :id, :platform, :handle, :priority, :_destroy ]
    )
  end
end
