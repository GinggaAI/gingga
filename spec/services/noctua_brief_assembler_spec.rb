require 'rails_helper'

RSpec.describe NoctuaBriefAssembler do
  describe '.call' do
    let(:user) { create(:user) }
    let(:brand) { create(:brand, user: user) }
    let!(:audience) { create(:audience, brand: brand) }
    let!(:product) { create(:product, brand: brand) }
    let!(:brand_channel) { create(:brand_channel, brand: brand) }

    let(:strategy_form) do
      {
        objective_of_the_month: 'awareness',
        monthly_themes: [ 'product launch', 'customer success' ],
        frequency_per_week: 4,
        resources_override: { ai_avatars: true, stock: false }
      }
    end

    subject { described_class.call(brand: brand, strategy_form: strategy_form) }

    it 'returns a hash with all required brand keys' do
      expect(subject).to include(
        :brand_name, :brand_slug, :industry, :value_proposition, :mission, :voice,
        :languages, :region, :timezone, :audiences, :products, :channels, :guardrails
      )
    end

    it 'includes strategy form fields' do
      expect(subject).to include(
        objective_of_the_month: 'awareness',
        monthly_themes: [ 'product launch', 'customer success' ],
        frequency_per_week: 4,
        resources_override: { ai_avatars: true, stock: false }
      )
    end

    it 'maps brand core fields correctly' do
      expect(subject[:brand_name]).to eq(brand.name)
      expect(subject[:brand_slug]).to eq(brand.slug)
      expect(subject[:industry]).to eq(brand.industry)
      expect(subject[:value_proposition]).to eq(brand.value_proposition)
      expect(subject[:mission]).to eq(brand.mission)
      expect(subject[:voice]).to eq(brand.voice)
      expect(subject[:region]).to eq(brand.region)
      expect(subject[:timezone]).to eq(brand.timezone)
      expect(subject[:guardrails]).to eq(brand.guardrails)
    end

    it 'structures languages correctly' do
      expect(subject[:languages]).to include(
        content: brand.content_language,
        account: brand.account_language,
        subtitles: brand.subtitle_languages,
        dub: brand.dub_languages
      )
    end

    it 'includes audiences array with expected shape' do
      expect(subject[:audiences]).to be_an(Array)
      expect(subject[:audiences].size).to eq(1)

      audience_data = subject[:audiences].first
      expect(audience_data).to include(
        :demographic_profile, :interests, :digital_behavior
      )
      expect(audience_data[:demographic_profile]).to eq(audience.demographic_profile)
      expect(audience_data[:interests]).to eq(audience.interests)
      expect(audience_data[:digital_behavior]).to eq(audience.digital_behavior)
    end

    it 'includes products array with expected shape' do
      expect(subject[:products]).to be_an(Array)
      expect(subject[:products].size).to eq(1)

      product_data = subject[:products].first
      expect(product_data).to include(:name, :description)
      expect(product_data[:name]).to eq(product.name)
      expect(product_data[:description]).to eq(product.description)
    end

    it 'includes channels array with expected shape' do
      expect(subject[:channels]).to be_an(Array)
      expect(subject[:channels].size).to eq(1)

      channel_data = subject[:channels].first
      expect(channel_data).to include(:platform, :handle, :priority)
      expect(channel_data[:platform]).to eq(brand_channel.platform)
      expect(channel_data[:handle]).to eq(brand_channel.handle)
      expect(channel_data[:priority]).to eq(brand_channel.priority)
    end

    context 'with empty strategy_form' do
      let(:strategy_form) { {} }

      it 'handles missing strategy form fields gracefully' do
        expect(subject[:objective_of_the_month]).to be_nil
        expect(subject[:monthly_themes]).to eq([])
        expect(subject[:frequency_per_week]).to be_nil
        expect(subject[:resources_override]).to eq({})
      end
    end

    context 'with brand having multiple related records' do
      let!(:audience2) { create(:audience, brand: brand) }
      let!(:product2) { create(:product, brand: brand) }
      let!(:channel2) { create(:brand_channel, :tiktok, brand: brand) }

      it 'includes all related records' do
        expect(subject[:audiences].size).to eq(2)
        expect(subject[:products].size).to eq(2)
        expect(subject[:channels].size).to eq(2)
      end
    end

    context 'when brand has no related records' do
      let(:brand_without_relations) { create(:brand, user: user) }

      subject { described_class.call(brand: brand_without_relations) }

      it 'returns empty arrays for relations' do
        expect(subject[:audiences]).to eq([])
        expect(subject[:products]).to eq([])
        expect(subject[:channels]).to eq([])
      end
    end
  end
end
