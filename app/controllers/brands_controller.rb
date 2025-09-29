class BrandsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_brand, only: [ :show, :edit, :update ]

  def show
    redirect_to edit_brand_path
  end

  def edit
    @brand = Brands::RetrievalService.for_edit(user: current_user, brand_id: params[:brand_id])
    @brands = Brands::RetrievalService.collection_for_user(user: current_user)
    @presenter = BrandPresenter.new(@brand, {
      notice: flash[:notice],
      brands_collection: @brands
    })
  end

  def create
    result = Brands::CreationService.new(user: current_user).call

    if result[:success]
      redirect_to edit_brand_path(brand_id: result[:data][:brand].id), notice: "New brand created successfully!"
    else
      redirect_to edit_brand_path, alert: result[:error]
    end
  end


  def update
    @brand = find_brand_for_update

    if @brand&.update(brand_params)
      redirect_to edit_brand_path(brand_id: @brand.id), notice: "Brand profile updated successfully!"
    else
      @brands = Brands::RetrievalService.collection_for_user(user: current_user)
      @presenter = BrandPresenter.new(@brand, {
        notice: flash[:notice],
        brands_collection: @brands
      })
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_brand
    result = Brands::RetrievalService.new(user: current_user, brand_id: params[:brand_id]).call
    @brand = result[:success] ? result[:data][:brand] : nil
  end

  def find_brand_for_update
    if params[:brand_id].present?
      current_user.brands.find(params[:brand_id])
    else
      current_user.brands.first || current_user.brands.create
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
