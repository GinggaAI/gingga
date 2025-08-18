class PlanningPresenter
  def initialize(params, brand: nil, current_plan: nil)
    @params = params
    @brand = brand
    @current_plan = current_plan
  end

  def display_month
    # If there's a month param but it's invalid, return error
    if @params[:month].present? && safe_month_param.nil?
      return "Invalid Month"
    end

    month = safe_month_param || current_month
    format_month_for_display(month)
  rescue
    "Invalid Month"
  end

  def safe_month_for_js
    return safe_month_param if safe_month_param
    current_month
  rescue
    current_month
  end

  def current_plan_json
    plan = current_plan
    plan ? plan.to_json.html_safe : "null"
  end

  def current_plan
    # If a plan was passed from the controller, use it
    return @current_plan if @current_plan

    return nil unless @brand

    # Check if we have a specific plan_id parameter
    if @params[:plan_id]
      return @brand.creas_strategy_plans.find_by(id: @params[:plan_id])
    end

    # If there's a month parameter but it's invalid, return nil (don't fallback to current month)
    if @params[:month].present? && safe_month_param.nil?
      return nil
    end

    # Use the month parameter if available, otherwise use current month
    month_to_search = safe_month_param || current_month

    # Try exact match first
    plan = @brand.creas_strategy_plans.where(month: month_to_search).order(created_at: :desc).first

    # Try normalized format if not found
    if plan.nil?
      normalized_month = normalize_month_format(month_to_search)
      plan = @brand.creas_strategy_plans.where(month: normalized_month).order(created_at: :desc).first
    end

    plan
  end

  private

  def safe_month_param
    month = @params[:month]
    return nil unless month.is_a?(String)

    # Only allow YYYY-MM or YYYY-M format
    return month if month.match?(/\A\d{4}-\d{1,2}\z/)
    nil
  end

  def current_month
    Date.current.strftime("%Y-%-m")
  end

  def format_month_for_display(month_string)
    return "Invalid Month" unless month_string

    year, month_num = month_string.split("-")
    raise ArgumentError unless year && month_num

    date = Date.new(year.to_i, month_num.to_i)
    date.strftime("%B %Y")
  rescue ArgumentError, Date::Error
    "Invalid Month"
  end

  def normalize_month_format(month)
    return month unless month.match?(/\A\d{4}-\d+\z/)

    year, month_num = month.split("-")
    if month_num.length == 1
      "#{year}-#{month_num.rjust(2, '0')}"
    else
      "#{year}-#{month_num.to_i}"
    end
  end
end
