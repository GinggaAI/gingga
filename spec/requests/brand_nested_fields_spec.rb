require 'rails_helper'

RSpec.describe 'Brand Nested Fields', type: :request do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }

  before do
    post user_session_path, params: {
      user: {
        email: user.email,
        password: 'password123'
      }
    }
  end

  describe 'GET /brand/edit' do
    context 'when brand has all required data' do
      before do
        create(:audience, brand: brand, name: 'Tech Professionals')
        create(:product, brand: brand, name: 'SaaS Platform')
        create(:brand_channel, brand: brand, platform: 'instagram', handle: '@techbrand')
      end

      it 'displays audiences section with existing data' do
        get edit_brand_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Audiences')
        expect(response.body).to include('Tech Professionals')
      end

      it 'displays products section with existing data' do
        get edit_brand_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Products')
        expect(response.body).to include('SaaS Platform')
      end

      it 'displays brand channels section with existing data' do
        get edit_brand_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Channels')
        expect(response.body).to include('@techbrand')
      end

      it 'shows strategy ready status' do
        get edit_brand_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Ready for strategy creation!')
      end
    end

    context 'when brand is missing required data' do
      before { create(:audience, brand: brand) }

      it 'shows missing requirements message' do
        get edit_brand_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Please add')
        expect(response.body).to include('products')
        expect(response.body).to include('brand_channels')
      end

      it 'displays empty sections for missing data' do
        get edit_brand_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include('No products defined')
        expect(response.body).to include('No channels configured')
      end
    end
  end

  describe 'POST /brand nested resources' do
    context 'creating audiences' do
      let(:audience_params) do
        {
          audiences_attributes: {
            '0' => {
              name: 'Young Professionals',
              demographic_profile: {
                age_range: '25-35',
                location: 'Urban areas'
              }.to_json,
              interests: [ 'technology', 'career growth' ].to_json
            }
          }
        }
      end

      it 'creates new audience for the brand' do
        expect {
          patch brand_path, params: { brand: audience_params }
        }.to change(brand.audiences, :count).by(1)

        audience = brand.audiences.last
        expect(audience.name).to eq('Young Professionals')
        expect(audience.demographic_profile['age_range']).to eq('25-35')
      end
    end

    context 'creating products' do
      let(:product_params) do
        {
          products_attributes: {
            '0' => {
              name: 'Premium Software',
              description: 'Enterprise-grade solution',
              pricing_info: '$199/month'
            }
          }
        }
      end

      it 'creates new product for the brand' do
        expect {
          patch brand_path, params: { brand: product_params }
        }.to change(brand.products, :count).by(1)

        product = brand.products.last
        expect(product.name).to eq('Premium Software')
        expect(product.description).to eq('Enterprise-grade solution')
      end
    end

    context 'creating brand channels' do
      let(:channel_params) do
        {
          brand_channels_attributes: {
            '0' => {
              platform: 'instagram',
              handle: '@newbrand',
              priority: 1
            }
          }
        }
      end

      it 'creates new channel for the brand' do
        expect {
          patch brand_path, params: { brand: channel_params }
        }.to change(brand.brand_channels, :count).by(1)

        channel = brand.brand_channels.last
        expect(channel.platform).to eq('instagram')
        expect(channel.handle).to eq('@newbrand')
      end
    end
  end

  describe 'validation and error handling' do
    context 'invalid nested attributes' do
      let(:invalid_params) do
        {
          # Set valid brand params first to trigger product validation
          name: 'Valid Brand',
          slug: 'valid-brand',
          industry: 'technology',
          voice: 'professional',
          products_attributes: {
            '0' => {
              name: '', # Invalid: name is required
              description: 'Valid description',
              pricing_info: '$100'
            }
          }
        }
      end

      it 'shows validation errors' do
        # Debug: verify the current product count
        initial_count = brand.products.count

        patch brand_path, params: { brand: invalid_params }

        # Reload the brand to get current state
        brand.reload
        final_count = brand.products.count

        # The request should fail due to validation errors
        expect(final_count).to eq(initial_count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'duplicate channel platforms' do
      before { create(:brand_channel, brand: brand, platform: 'instagram') }

      let(:duplicate_params) do
        {
          brand_channels_attributes: {
            '0' => {
              platform: 'instagram', # Duplicate platform
              handle: '@anotherbrand'
            }
          }
        }
      end

      it 'prevents duplicate platforms' do
        expect {
          patch brand_path, params: { brand: duplicate_params }
        }.not_to change(brand.brand_channels, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'deletion of nested resources' do
    context 'removing audiences' do
      let!(:audience) { create(:audience, brand: brand, name: 'Old Audience') }

      let(:delete_params) do
        {
          audiences_attributes: {
            '0' => {
              id: audience.id,
              _destroy: '1'
            }
          }
        }
      end

      it 'removes the audience' do
        expect {
          patch brand_path, params: { brand: delete_params }
        }.to change(brand.audiences, :count).by(-1)
      end
    end

    context 'removing products' do
      let!(:product) { create(:product, brand: brand, name: 'Old Product') }

      let(:delete_params) do
        {
          products_attributes: {
            '0' => {
              id: product.id,
              _destroy: '1'
            }
          }
        }
      end

      it 'removes the product' do
        expect {
          patch brand_path, params: { brand: delete_params }
        }.to change(brand.products, :count).by(-1)
      end
    end
  end
end
