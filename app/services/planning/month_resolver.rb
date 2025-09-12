module Planning
  class MonthResolver
    Result = Struct.new(:month, :display_month, keyword_init: true)

    def initialize(month_param = nil)
      @month_param = month_param
    end

    def call
      month = resolve_month
      display_month = format_month_for_display(month)

      Result.new(month: month, display_month: display_month)
    rescue StandardError => e
      Rails.logger.error "MonthResolver error: #{e.message}"
      Result.new(month: current_month, display_month: "Invalid Month")
    end

    private

    attr_reader :month_param

    def resolve_month
      return current_month unless month_param.present?
      return month_param if valid_month_format?(month_param)

      current_month
    end

    def valid_month_format?(month)
      month.is_a?(String) && month.match?(/\A\d{4}-\d{1,2}\z/)
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
