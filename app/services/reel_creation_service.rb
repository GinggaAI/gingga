class ReelCreationService
  def initialize(user:, brand: nil, template: nil, params: nil)
    @user = user
    @brand = brand || (user&.current_brand)
    @template = template
    @params = params
  end

  def initialize_reel
    return failure_result("Invalid template") unless valid_template?(@template)

    template_service = template_service_for(@template)
    template_service.new(user: @user, brand: @brand, template: @template).initialize_reel
  end

  def call
    return failure_result("No parameters provided") unless @params.present?

    template = @params[:template]
    return failure_result("Invalid template") unless valid_template?(template)

    template_service = template_service_for(template)
    template_service.new(user: @user, brand: @brand, params: @params).call
  end

  private

  def template_service_for(template)
    case template
    when "only_avatars"
      Reels::OnlyAvatarsCreationService
    when "avatar_and_video"
      Reels::AvatarAndVideoCreationService
    when "narration_over_7_images"
      Reels::NarrationOver7ImagesCreationService
    when "one_to_three_videos"
      Reels::OneToThreeVideosCreationService
    end
  end

  def valid_template?(template)
    %w[only_avatars avatar_and_video narration_over_7_images one_to_three_videos].include?(template)
  end

  def success_result(reel)
    { success: true, reel: reel, error: nil }
  end

  def failure_result(error_message)
    { success: false, reel: nil, error: error_message }
  end
end
