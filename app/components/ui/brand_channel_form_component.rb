class Ui::BrandChannelFormComponent < ViewComponent::Base
  def initialize(form:, brand_channel:, index:)
    @form = form
    @brand_channel = brand_channel
    @index = index
  end

  private

  attr_reader :form, :brand_channel, :index

  def platform_options
    BrandChannel.platforms.map do |key, value|
      [ key.humanize, key ]
    end
  end

  def priority_options
    (1..5).map { |i| [ priority_label(i), i ] }
  end

  def priority_label(priority)
    case priority
    when 1 then "1 - Highest Priority"
    when 2 then "2 - High Priority"
    when 3 then "3 - Medium Priority"
    when 4 then "4 - Low Priority"
    when 5 then "5 - Lowest Priority"
    end
  end
end
