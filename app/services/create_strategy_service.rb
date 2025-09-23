class CreateStrategyService
  Result = Struct.new(:success?, :plan, :error, keyword_init: true)

  def self.call(**args)
    new(**args).call
  end

  def initialize(user:, brand:, month:, strategy_params: {})
    @user = user
    @brand = brand
    @month = month
    @strategy_params = strategy_params
  end

  def call
    validate_inputs!
    strategy_form = build_strategy_form
    brief = NoctuaBriefAssembler.call(brand: @brand, strategy_form: strategy_form, month: @month)
    plan = Creas::NoctuaStrategyService.new(
      user: @user,
      brief: brief,
      brand: @brand,
      month: @month,
      strategy_form: strategy_form
    ).call

    Result.new(success?: true, plan: plan)
  rescue => e
    Rails.logger.error "Strategy creation failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    Result.new(success?: false, error: e.message)
  end

  private

  def validate_inputs!
    raise ArgumentError, "User is required" unless @user
    raise ArgumentError, "Brand is required" unless @brand
    raise ArgumentError, "Month is required" unless @month.present?
  end

  def build_strategy_form
    {
      primary_objective: @strategy_params[:primary_objective].presence || "awareness",
      objective_of_the_month: @strategy_params[:objective_of_the_month],
      objective_details: @strategy_params[:objective_details],
      frequency_per_week: parsed_frequency,
      monthly_themes: parsed_themes
    }
  end

  def parsed_frequency
    (@strategy_params[:frequency_per_week].presence || 3).to_i.clamp(1, 7)
  end

  def parsed_themes
    themes = @strategy_params[:monthly_themes]
    return default_themes unless themes.present?

    if themes.is_a?(String)
      themes.split(",").map(&:strip).reject(&:blank?)
    else
      Array(themes).reject(&:blank?)
    end.presence || default_themes
  end


  def default_themes
    [ "Brand awareness", "Product showcase", "Community engagement" ]
  end
end
