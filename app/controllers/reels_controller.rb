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
      
      # Preload data from smart planning if provided
      preload_smart_planning_data if params[:smart_planning_data].present?
      
      setup_presenter(template)
      render_template_view(template)
    else
      redirect_to reels_path, alert: result[:error]
    end
  end

  def create
    result = ReelCreationService.new(user: current_user, params: reel_params).call

    if result[:success]
      redirect_to result[:reel], notice: "Reel created successfully! Your video is being generated with HeyGen and will be ready shortly."
    else
      @reel = result[:reel]
      template = @reel&.template || reel_params[:template]
      setup_presenter(template)
      render_template_view(template, status: :unprocessable_entity)
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

  def valid_template?(template)
    %w[only_avatars avatar_and_video narration_over_7_images one_to_three_videos].include?(template)
  end

  def render_template_view(template, **options)
    case template
    when "only_avatars", "avatar_and_video", "one_to_three_videos"
      render "reels/scene_based", **options
    when "narration_over_7_images"
      render "reels/narrative", **options
    else
      # This should never happen due to validation, but add safety net
      redirect_to reels_path, alert: "Invalid template"
    end
  end

  def setup_presenter(template)
    case template
    when "only_avatars", "avatar_and_video", "one_to_three_videos"
      @presenter = ReelSceneBasedPresenter.new(reel: @reel, current_user: current_user)
    when "narration_over_7_images"
      @presenter = ReelNarrativePresenter.new(reel: @reel, current_user: current_user)
    end
  end

  def preload_smart_planning_data
    begin
      planning_data = JSON.parse(params[:smart_planning_data])
      
      Rails.logger.info "Preloading smart planning data: #{planning_data.keys}"
      
      # Update reel basic info
      @reel.update!(
        title: planning_data["title"] || planning_data["content_name"],
        description: planning_data["description"] || planning_data["post_description"]
      )
      
      # Preload scenes if shotplan exists
      if planning_data["shotplan"] && planning_data["shotplan"]["scenes"]
        scenes = planning_data["shotplan"]["scenes"]
        Rails.logger.info "Found #{scenes.length} scenes to preload"
        preload_scenes_from_shotplan(scenes)
      else
        Rails.logger.info "No shotplan or scenes found in planning data"
      end
      
    rescue JSON::ParserError => e
      Rails.logger.error "Failed to parse smart planning data: #{e.message}"
      Rails.logger.error "Raw planning data: #{params[:smart_planning_data]}"
    rescue StandardError => e
      Rails.logger.error "Failed to preload smart planning data: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end

  def preload_scenes_from_shotplan(scenes)
    # Clear existing scenes first
    @reel.reel_scenes.destroy_all
    
    # Get user's avatars and voices (try active first, then any)
    user_avatar = current_user.avatars.active.first || current_user.avatars.first
    user_voice = current_user.voices.active.first || current_user.voices.first
    
    # Use system defaults if user has no avatars/voices
    default_avatar_id = user_avatar&.avatar_id || "avatar_001" 
    default_voice_id = user_voice&.voice_id || "voice_001"
    
    Rails.logger.info "Using default avatar: #{default_avatar_id}, voice: #{default_voice_id}"
    
    created_scenes = 0
    scenes.each_with_index do |scene_data, index|
      Rails.logger.info "Processing scene #{index + 1}: #{scene_data.inspect}"
      
      # Extract script from various possible fields
      script = scene_data["voiceover"] || scene_data["script"] || scene_data["description"]
      
      # Skip if no script content is available
      if script.blank?
        Rails.logger.warn "Skipping scene #{index + 1}: no script content found"
        next
      end
      
      # Use provided IDs or fallback to defaults
      avatar_id = scene_data["avatar_id"].presence || default_avatar_id
      voice_id = scene_data["voice_id"].presence || default_voice_id
      
      begin
        @reel.reel_scenes.create!(
          scene_number: index + 1,
          avatar_id: avatar_id,
          voice_id: voice_id,
          script: script.strip,
          video_type: "avatar"
        )
        created_scenes += 1
        Rails.logger.info "Created scene #{index + 1} successfully"
      rescue => e
        Rails.logger.error "Failed to create scene #{index + 1}: #{e.message}"
      end
    end
    
    Rails.logger.info "Successfully created #{created_scenes} scenes from #{scenes.length} input scenes"
  end
end
