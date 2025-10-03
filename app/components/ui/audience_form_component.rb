class Ui::AudienceFormComponent < ViewComponent::Base
  def initialize(form:, audience:, index:)
    @form = form
    @audience = audience
    @index = index
  end

  private

  attr_reader :form, :audience, :index

  def demographic_profile_value
    return "" unless audience.demographic_profile.present?
    audience.demographic_profile.to_json
  end

  def demographic_field_value(field_name)
    return "" unless audience.demographic_profile.present?
    return "" unless audience.demographic_profile.is_a?(Hash)
    audience.demographic_profile[field_name.to_s] || ""
  end

  def interests_value
    return "" unless audience.interests.present?

    if audience.interests.is_a?(Array)
      audience.interests.join(", ")
    else
      audience.interests.to_s
    end
  end

  def digital_behavior_value
    return "" unless audience.digital_behavior.present?

    if audience.digital_behavior.is_a?(Array)
      audience.digital_behavior.join(", ")
    else
      audience.digital_behavior.to_s
    end
  end
end
