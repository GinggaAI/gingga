module Reels
  class BaseCreationService
    def initialize(user:, template: nil, params: nil)
      @user = user
      @template = template
      @params = params
    end

    def initialize_reel
      reel = @user.reels.build(template: @template, status: "draft")
      setup_template_specific_fields(reel)
      success_result(reel)
    end

    def call
      reel = @user.reels.build(reel_params)
      setup_template_specific_fields(reel) if reel.new_record?
      
      if reel.save
        success_result(reel)
      else
        failure_result("Validation failed", reel)
      end
    end

    private

    def reel_params
      @params.merge(status: "draft")
    end

    def setup_template_specific_fields(reel)
      # Override in subclasses
    end

    def success_result(reel)
      { success: true, reel: reel, error: nil }
    end

    def failure_result(error_message, reel = nil)
      { success: false, reel: reel, error: error_message }
    end
  end
end