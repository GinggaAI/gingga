class BrandPresenter
  def initialize(brand, params = {})
    @brand = brand
    @params = params
  end

  def name
    @brand.name.presence || "Untitled Brand"
  end

  def audiences
    @brand.audiences.order(:created_at)
  end

  def products
    @brand.products.order(:created_at)
  end

  def brand_channels
    @brand.brand_channels.order(:priority, :created_at)
  end

  def has_audiences?
    audiences.exists?
  end

  def has_products?
    products.exists?
  end

  def has_brand_channels?
    brand_channels.exists?
  end

  def missing_requirements
    missing = []
    missing << "audiences" unless has_audiences?
    missing << "products" unless has_products?
    missing << "brand_channels" unless has_brand_channels?
    missing
  end

  def strategy_ready?
    missing_requirements.empty?
  end

  def strategy_readiness_message
    if strategy_ready?
      "Your brand is ready for strategy creation!"
    else
      missing = missing_requirements
      "Please add #{missing.join(', ')} before creating a strategy."
    end
  end

  def audience_demographics_summary
    return "No audiences defined" unless has_audiences?

    ages = audiences.map { |a| a.demographic_profile.dig("age_range") }.compact
    locations = audiences.map { |a| a.demographic_profile.dig("location") }.compact

    summary_parts = []
    summary_parts << "#{ages.join(', ')} years old" if ages.any?
    summary_parts << "from #{locations.join(', ')}" if locations.any?
    summary_parts.join(" ")
  end

  def products_summary
    return "No products defined" unless has_products?

    product_names = products.pluck(:name)
    case product_names.size
    when 1
      product_names.first
    when 2
      product_names.join(" and ")
    else
      "#{product_names.first} and #{product_names.size - 1} more"
    end
  end

  def channels_summary
    return "No channels configured" unless has_brand_channels?

    channels = brand_channels.map(&:platform)
    channels.map(&:capitalize).join(", ")
  end

  private

  attr_reader :brand, :params
end
