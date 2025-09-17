class ReelsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_reel, only: [ :show, :edit ]

  def index
    @reels = current_user.reels.order(created_at: :desc)
  end

  def show
    # Show individual reel
  end

  def edit
    return error_handler.handle_edit_access_error unless @reel.status == "draft"

    presenter_result = setup_presenter_for_reel(@reel)

    if presenter_result.success?
      @presenter = presenter_result.data[:presenter]
      render presenter_result.data[:view_template]
    else
      redirect_to reels_path, alert: "Error loading reel for editing: #{presenter_result.error}"
    end
  end

  def new
    # Validate template parameter against allowed templates to prevent dynamic render attacks
    unless valid_template?(params[:template])
      redirect_to reels_path, alert: I18n.t("reels.errors.invalid_template")
      return
    end

    form_result = Reels::FormSetupService.new(
      user: current_user,
      template: params[:template],
      smart_planning_data: params[:smart_planning_data]
    ).call

    if form_result[:success]
      @reel = form_result[:data][:reel]
      @presenter = form_result[:data][:presenter]
      # Use safe render with validated template path
      render_safe_template(form_result[:data][:view_template])
    else
      error_handler.handle_form_setup_error(form_result[:error])
    end
  end

  def create
    creation_result = ReelCreationService.new(
      user: current_user,
      params: reel_params
    ).call

    if creation_result[:success]
      redirect_to creation_result[:reel],
        notice: "Reel created successfully! Your video is being generated with HeyGen and will be ready shortly."
    else
      error_handler.handle_creation_error(creation_result, reel_params)
    end
  end

  private

  def set_reel
    @reel = current_user.reels.find(params[:id])
  end

  def reel_params
    params.require(:reel).permit(
      :template, :title, :description, :category, :use_ai_avatar, :additional_instructions,
      :story_content, :music_preference, :style_preference,
      reel_scenes_attributes: [ :id, :scene_number, :avatar_id, :voice_id, :script, :video_type, :_destroy ]
    )
  end

  def setup_presenter_for_reel(reel)
    Reels::PresenterService.new(
      reel: reel,
      template: reel.template,
      current_user: current_user
    ).call
  end

  def error_handler
    @error_handler ||= Reels::ErrorHandlingService.new(controller: self)
  end

  # Security: Validate template parameter against whitelist
  def valid_template?(template)
    allowed_templates = %w[only_avatars avatar_and_video one_to_three_videos narration_over_7_images]
    allowed_templates.include?(template)
  end

  # Security: Safe template rendering with path validation
  def render_safe_template(view_template)
    allowed_view_templates = %w[reels/scene_based reels/narrative]

    if allowed_view_templates.include?(view_template)
      render view_template
    else
      Rails.logger.error "Security: Attempted to render unauthorized template: #{view_template}"
      redirect_to reels_path, alert: I18n.t("reels.errors.invalid_template")
    end
  end
end
