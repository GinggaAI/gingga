module Settings
  class ApiTokenResponder
    def initialize(controller, provider)
      @controller = controller
      @provider = provider
    end

    def respond_to_update(result)
      if result.success?
        redirect_with_notice("settings.#{@provider}.save_success")
      else
        redirect_with_alert("settings.#{@provider}.save_failed", error: result.error)
      end
    end

    def respond_to_validation(result, count: nil, message_key: nil)
      if result.success?
        if message_key && count
          redirect_with_notice(message_key, count: count)
        else
          redirect_with_notice("settings.#{@provider}.validation_success")
        end
      else
        redirect_with_alert("settings.#{@provider}.validation_failed", error: result.error)
      end
    end

    private

    def redirect_with_notice(key, **options)
      @controller.redirect_to(
        @controller.settings_path,
        notice: I18n.t(key, **options),
        allow_other_host: false
      )
    end

    def redirect_with_alert(key, **options)
      @controller.redirect_to(
        @controller.settings_path,
        alert: I18n.t(key, **options),
        allow_other_host: false
      )
    end
  end
end
