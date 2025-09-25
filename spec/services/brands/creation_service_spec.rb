require 'rails_helper'

RSpec.describe Brands::CreationService do
  let(:user) { create(:user) }
  let(:service) { described_class.new(user: user) }

  describe '#call' do
    context 'when brand creation is successful' do
      it 'creates a new brand for the user' do
        expect { service.call }.to change(user.brands, :count).by(1)
      end

      it 'returns success result with brand data' do
        result = service.call

        expect(result[:success]).to be true
        expect(result[:data][:brand]).to be_a(Brand)
        expect(result[:data][:brand].user).to eq(user)
        expect(result[:error]).to be_nil
      end

      it 'creates brand with default attributes' do
        result = service.call
        brand = result[:data][:brand]

        expect(brand.name).to eq("New Brand")
        expect(brand.slug).to match(/^brand-\d+$/)
        expect(brand.industry).to eq("other")
        expect(brand.voice).to eq("professional")
      end

      it 'generates unique slugs for multiple brands' do
        first_result = service.call
        second_result = described_class.new(user: user).call

        first_slug = first_result[:data][:brand].slug
        second_slug = second_result[:data][:brand].slug

        expect(first_slug).not_to eq(second_slug)
        expect(first_slug).to match(/^brand-\d+$/)
        expect(second_slug).to match(/^brand-\d+$/)
      end
    end

    context 'when user is not provided' do
      let(:service) { described_class.new(user: nil) }

      it 'returns failure result' do
        result = service.call

        expect(result[:success]).to be false
        expect(result[:data]).to be_nil
        expect(result[:error]).to include("Failed to create brand")
      end
    end

    context 'when brand validation fails' do
      before do
        allow_any_instance_of(Brand).to receive(:save).and_return(false)
        allow_any_instance_of(Brand).to receive(:errors).and_return(
          double(full_messages: [ "Name can't be blank", "Industry can't be blank" ])
        )
      end

      it 'returns failure result with validation errors' do
        result = service.call

        expect(result[:success]).to be false
        expect(result[:data]).to be_nil
        expect(result[:error]).to eq("Name can't be blank, Industry can't be blank")
      end
    end
  end

  describe '#generate_unique_slug' do
    it 'generates sequential slugs when brands already exist' do
      create(:brand, user: user, slug: "brand-1")
      create(:brand, user: user, slug: "brand-2")

      result = service.call

      expect(result[:data][:brand].slug).to eq("brand-3")
    end

    it 'handles gaps in slug numbering' do
      create(:brand, user: user, slug: "brand-1")
      create(:brand, user: user, slug: "brand-3")

      result = service.call

      expect(result[:data][:brand].slug).to eq("brand-2")
    end
  end
end
