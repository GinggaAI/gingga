module Reels
  class ErrorHandlingService
    def initialize(controller:)
      @controller = controller
    end

    def handle_creation_error(creation_result, reel_params)
      reel = creation_result[:reel]
      template = reel&.template || reel_params[:template]

      presenter_result = setup_error_presenter(reel, template)

      if presenter_result.success?
        render_form_with_errors(reel, presenter_result)
      else
        render_json_error(presenter_result.error)
      end
    end

    def handle_form_setup_error(error_message)
      @controller.redirect_to @controller.reels_path, alert: error_message
    end

    def handle_edit_access_error
      @controller.redirect_to @controller.reels_path,
        alert: "Only draft reels can be edited"
    end

    private

    def setup_error_presenter(reel, template)
      PresenterService.new(
        reel: reel,
        template: template,
        current_user: @controller.current_user
      ).call
    end

    def render_form_with_errors(reel, presenter_result)
      @controller.instance_variable_set(:@reel, reel)
      @controller.instance_variable_set(:@presenter, presenter_result.data[:presenter])

      @controller.render presenter_result.data[:view_template],
        status: :unprocessable_entity
    end

    def render_json_error(error_message)
      @controller.render json: { error: error_message },
        status: :unprocessable_entity
    end
  end
end
