class NoctuaBriefAssembler
  def self.call(brand:, strategy_form: {})
    # binding.break
    brand = Brand.includes(:audiences, :products, :brand_channels).find(brand.id)
    {
      brand_name: brand.name,
      brand_slug: brand.slug,
      industry: brand.industry,
      value_proposition: brand.value_proposition,
      mission: brand.mission,
      voice: brand.voice,
      languages: {
        content: brand.content_language,
        account: brand.account_language,
        subtitles: brand.subtitle_languages,
        dub: brand.dub_languages
      },
      region: brand.region,
      timezone: brand.timezone,
      audiences: brand.audiences.map { |a|
        {
          demographic_profile: a.demographic_profile,
          interests: a.interests,
          digital_behavior: a.digital_behavior
        }
      },
      products: brand.products.map { |p|
        {
          name: p.name,
          description: p.description
        }
      },
      channels: brand.brand_channels.map { |c|
        {
          platform: c.platform,
          handle: c.handle,
          priority: c.priority
        }
      },
      guardrails: brand.guardrails,
      # Monthly form fields:
      objective_of_the_month: strategy_form[:objective_of_the_month],
      monthly_themes: strategy_form[:monthly_themes] || [],
      frequency_per_week: strategy_form[:frequency_per_week],
      resources_override: strategy_form[:resources_override] || {}
    }
  end
end
