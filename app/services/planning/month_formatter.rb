module Planning
  class MonthFormatter
    FALLBACK_TEXT = "Current Month".freeze

    def self.format_for_display(month_string)
      new(month_string).format_for_display
    end

    def initialize(month_string)
      @month_string = month_string
    end

    def format_for_display
      return FALLBACK_TEXT unless @month_string.present?

      parse_and_format
    rescue ArgumentError, NoMethodError
      @month_string
    end

    private

    def parse_and_format
      year, month_num = @month_string.split("-")
      date = Date.new(year.to_i, month_num.to_i)
      date.strftime("%B %Y")
    end
  end
end
