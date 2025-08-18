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

  def interests_value
    return "" unless audience.interests.present?
    audience.interests.join(", ")
  end

  def digital_behavior_value
    return "" unless audience.digital_behavior.present?
    audience.digital_behavior.join(", ")
  end
end
