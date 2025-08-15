module Ui
  class ToastComponentPreview < ViewComponent::Preview
    def success
      render(Ui::ToastComponent.new(
        message: "Brand profile updated successfully!",
        variant: :success
      ))
    end

    def warning
      render(Ui::ToastComponent.new(
        message: "Please review your content settings before proceeding.",
        variant: :warning
      ))
    end

    def error
      render(Ui::ToastComponent.new(
        message: "Failed to generate reel. Please try again.",
        variant: :error
      ))
    end

    def info
      render(Ui::ToastComponent.new(
        message: "Your reel is being processed and will be ready shortly.",
        variant: :info
      ))
    end

    def not_dismissible
      render(Ui::ToastComponent.new(
        message: "This message cannot be dismissed manually.",
        variant: :info,
        dismissible: false
      ))
    end

    def no_auto_dismiss
      render(Ui::ToastComponent.new(
        message: "This message stays until manually dismissed.",
        variant: :success,
        auto_dismiss: false
      ))
    end
  end
end
