require 'rails_helper'

RSpec.describe Ui::AudienceFormComponent, type: :component do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }
  let(:audience) { build(:audience, brand: brand) }
  let(:form_builder) { double("FormBuilder") }

  before do
    allow(form_builder).to receive(:object).and_return(audience)
    allow(form_builder).to receive(:options).and_return({ child_index: 0 })
  end

  describe '#interests_value' do
    context 'when interests is an array' do
      it 'joins array elements with comma and space' do
        audience.interests = [ 'technology', 'fitness', 'travel' ]
        component = described_class.new(form: form_builder, audience: audience, index: 0)

        expect(component.send(:interests_value)).to eq('technology, fitness, travel')
      end
    end

    context 'when interests is a string' do
      it 'returns the string as-is' do
        audience.interests = 'eco-friendly products, sustainability, office management'
        component = described_class.new(form: form_builder, audience: audience, index: 0)

        expect(component.send(:interests_value)).to eq('eco-friendly products, sustainability, office management')
      end
    end

    context 'when interests is nil or empty' do
      it 'returns empty string' do
        audience.interests = nil
        component = described_class.new(form: form_builder, audience: audience, index: 0)

        expect(component.send(:interests_value)).to eq('')
      end

      it 'returns empty string for empty array' do
        audience.interests = []
        component = described_class.new(form: form_builder, audience: audience, index: 0)

        expect(component.send(:interests_value)).to eq('')
      end
    end
  end

  describe '#digital_behavior_value' do
    context 'when digital_behavior is an array' do
      it 'joins array elements with comma and space' do
        audience.digital_behavior = [ 'social_media_active', 'online_shopper' ]
        component = described_class.new(form: form_builder, audience: audience, index: 0)

        expect(component.send(:digital_behavior_value)).to eq('social_media_active, online_shopper')
      end
    end

    context 'when digital_behavior is a string' do
      it 'returns the string as-is' do
        audience.digital_behavior = 'social_media_active, email_subscriber, mobile_first'
        component = described_class.new(form: form_builder, audience: audience, index: 0)

        expect(component.send(:digital_behavior_value)).to eq('social_media_active, email_subscriber, mobile_first')
      end
    end

    context 'when digital_behavior is nil or empty' do
      it 'returns empty string' do
        audience.digital_behavior = nil
        component = described_class.new(form: form_builder, audience: audience, index: 0)

        expect(component.send(:digital_behavior_value)).to eq('')
      end
    end
  end

  describe '#demographic_profile_value' do
    context 'when demographic_profile is present' do
      it 'returns JSON string' do
        profile = { 'age_range' => '25-34', 'location' => 'US' }
        audience.demographic_profile = profile
        component = described_class.new(form: form_builder, audience: audience, index: 0)

        expect(component.send(:demographic_profile_value)).to eq(profile.to_json)
      end
    end

    context 'when demographic_profile is nil or empty' do
      it 'returns empty string' do
        audience.demographic_profile = nil
        component = described_class.new(form: form_builder, audience: audience, index: 0)

        expect(component.send(:demographic_profile_value)).to eq('')
      end
    end
  end

  describe '#demographic_field_value' do
    context 'when demographic_profile contains the field' do
      it 'returns the field value' do
        audience.demographic_profile = { 'age_range' => '25-34', 'location' => 'US' }
        component = described_class.new(form: form_builder, audience: audience, index: 0)

        expect(component.send(:demographic_field_value, :age_range)).to eq('25-34')
        expect(component.send(:demographic_field_value, 'location')).to eq('US')
      end
    end

    context 'when demographic_profile does not contain the field' do
      it 'returns empty string' do
        audience.demographic_profile = { 'age_range' => '25-34' }
        component = described_class.new(form: form_builder, audience: audience, index: 0)

        expect(component.send(:demographic_field_value, :gender)).to eq('')
      end
    end

    context 'when demographic_profile is not a hash' do
      it 'returns empty string' do
        audience.demographic_profile = "invalid"
        component = described_class.new(form: form_builder, audience: audience, index: 0)

        expect(component.send(:demographic_field_value, :age_range)).to eq('')
      end
    end
  end
end
