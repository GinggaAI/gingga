class ReelsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_reel, only: [ :show ]

  def index
    @reels = current_user.reels.order(created_at: :desc)
  end

  def show
    # Show individual reel
  end

  def new
    template = params[:template]
    return redirect_to reels_path, alert: "Invalid template" unless valid_template?(template)
    
    result = ReelCreationService.new(user: current_user, template: template).initialize_reel
    
    if result[:success]
      @reel = result[:reel]
      setup_presenter(template)
      render template_view(template)
    else
      redirect_to reels_path, alert: result[:error]
    end
  end

  def create
    result = ReelCreationService.new(user: current_user, params: reel_params).call
    
    if result[:success]
      redirect_to result[:reel], notice: "Reel created successfully! Your reel is being generated."
    else
      @reel = result[:reel]
      setup_presenter(@reel.template)
      render template_view(@reel.template), status: :unprocessable_entity
    end
  end

  private

  def set_reel
    @reel = current_user.reels.find(params[:id])
  end

  def reel_params
    params.require(:reel).permit(
      :template, :title, :description,
      reel_scenes_attributes: [ :id, :scene_number, :avatar_id, :voice_id, :script, :_destroy ]
    )
  end

  def valid_template?(template)
    %w[solo_avatars avatar_and_video narration_over_7_images one_to_three_videos].include?(template)
  end

  def template_view(template)
    case template
    when "solo_avatars", "avatar_and_video", "one_to_three_videos"
      :scene_based
    when "narration_over_7_images"
      :narrative
    end
  end

  def setup_presenter(template)
    case template
    when "solo_avatars", "avatar_and_video", "one_to_three_videos"
      @presenter = ReelSceneBasedPresenter.new(reel: @reel, current_user: current_user)
    when "narration_over_7_images"
      @presenter = ReelNarrativePresenter.new(reel: @reel, current_user: current_user)
    end
  end
end
