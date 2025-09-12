module Planning
  class ContentDetailsService
    Result = Struct.new(:success?, :html, :error_message, :status_code, keyword_init: true)

    def initialize(content_data:, user:)
      @content_data = content_data
      @user = user
    end

    def call
      return validation_error unless valid_content_data?

      begin
        html = render_content_details
        Result.new(success?: true, html: html)
      rescue JSON::ParserError => e
        log_json_error(e)
        Result.new(
          success?: false,
          error_message: "Invalid content data format",
          status_code: :bad_request
        )
      rescue StandardError => e
        log_rendering_error(e)
        Result.new(
          success?: false,
          error_message: "Failed to render content details",
          status_code: :internal_server_error
        )
      end
    end

    private

    attr_reader :content_data, :user

    def valid_content_data?
      content_data.present?
    end

    def validation_error
      Result.new(
        success?: false,
        error_message: "Content data is required",
        status_code: :bad_request
      )
    end

    def render_content_details
      content_piece = JSON.parse(content_data)
      presenter = build_presenter

      Rails.logger.info "ContentDetailsService - content_piece keys: #{content_piece.keys}"

      ApplicationController.renderer.render(
        partial: "plannings/content_detail",
        locals: { content_piece: content_piece, presenter: presenter },
        formats: [ :html ]
      )
    end

    def build_presenter
      ::PlanningPresenter.new({}, brand: user_brand, current_plan: nil)
    end

    def user_brand
      @user_brand ||= BrandResolver.call(user)
    end

    def log_json_error(error)
      Rails.logger.error "ContentDetailsService: Failed to parse content data: #{error.message}"
      Rails.logger.error "Raw content_data: #{content_data}"
    end

    def log_rendering_error(error)
      Rails.logger.error "ContentDetailsService: Error rendering content details: #{error.message}"
      Rails.logger.error "Backtrace: #{error.backtrace.join("\n")}"
    end
  end
end
