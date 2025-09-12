module Planning
  class MonthResolver
    Result = Struct.new(:month, :display_month, keyword_init: true)

    def initialize(month_param = nil)
      @month_param = month_param
    end

    def call
      month = resolve_month

      # If month is nil (invalid parameter was provided), return error state
      if month.nil?
        return Result.new(month: nil, display_month: "Invalid Month")
      end

      display_month = format_month_for_display(month)

      Result.new(month: month, display_month: display_month)
    rescue StandardError => e
      Rails.logger.error "MonthResolver error: #{e.message}"
      Result.new(month: nil, display_month: "Invalid Month")
    end

    private

    attr_reader :month_param

    def resolve_month
      return current_month unless month_param.present?
      return month_param if valid_month_format?(month_param)

      # If month_param is present but invalid, return nil instead of falling back
      # This prevents XSS and other malicious inputs from getting processed
      nil
    end

    def valid_month_format?(month)
      return false unless month.is_a?(String) && month.match?(/\A\d{4}-\d{1,2}\z/)

      # Check if it's actually a valid date
      year, month_num = month.split("-")
      Date.new(year.to_i, month_num.to_i)
      true
    rescue ArgumentError, Date::Error
      false
    end

    def current_month
      Date.current.strftime("%Y-%-m")
    end

    def format_month_for_display(month_string)
      return "Invalid Month" unless month_string

      year, month_num = month_string.split("-")
      return "Invalid Month" unless year && month_num

      date = Date.new(year.to_i, month_num.to_i)
      date.strftime("%B %Y")
    rescue ArgumentError, Date::Error
      "Invalid Month"
    end
  end
end
