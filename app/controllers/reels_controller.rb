class ReelsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_reel, only: [ :show ]

  def index
    @reels = current_user.reels.order(created_at: :desc)
  end

  def show
    # Show individual reel
  end

  def scene_based
    @reel = current_user.reels.build(mode: "scene_based")
    3.times { |i| @reel.reel_scenes.build(scene_number: i + 1) }
  end

  def create_scene_based
    @reel = current_user.reels.build(scene_based_params)
    @reel.mode = "scene_based"
    @reel.status = "draft"

    if @reel.save
      redirect_to @reel, notice: "Scene-based reel created successfully! Your reel is being generated."
    else
      3.times { |i| @reel.reel_scenes.build(scene_number: i + 1) if @reel.reel_scenes.find_by(scene_number: i + 1).nil? }
      render :scene_based, status: :unprocessable_entity
    end
  end

  def narrative
    @reel = current_user.reels.build(mode: "narrative")
  end

  def create_narrative
    @reel = current_user.reels.build(narrative_params)
    @reel.mode = "narrative"
    @reel.status = "draft"

    if @reel.save
      redirect_to @reel, notice: "Narrative reel created successfully! Your reel is being generated."
    else
      render :narrative, status: :unprocessable_entity
    end
  end

  private

  def set_reel
    @reel = current_user.reels.find(params[:id])
  end

  def scene_based_params
    params.require(:reel).permit(
      :title, :description, :use_ai_avatar, :additional_instructions,
      reel_scenes_attributes: [ :id, :scene_number, :avatar_id, :voice_id, :script, :_destroy ]
    )
  end

  def narrative_params
    params.require(:reel).permit(
      :title, :description, :category, :format, :story_content,
      :music_preference, :style_preference
    )
  end
end
