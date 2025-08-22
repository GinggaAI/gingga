import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["audiencesContainer", "productsContainer", "channelsContainer"]
  static values = {
    audienceIndex: Number,
    productIndex: Number,
    channelIndex: Number
  }

  connect() {
    this.setupEventListeners()
  }

  setupEventListeners() {
    // Add Audience functionality
    const addAudienceBtn = document.getElementById('add-audience-btn')
    if (addAudienceBtn && this.hasAudiencesContainerTarget) {
      addAudienceBtn.addEventListener('click', () => this.addAudience())
    }

    // Add Product functionality
    const addProductBtn = document.getElementById('add-product-btn')
    if (addProductBtn && this.hasProductsContainerTarget) {
      addProductBtn.addEventListener('click', () => this.addProduct())
    }

    // Add Channel functionality
    const addChannelBtn = document.getElementById('add-channel-btn')
    if (addChannelBtn && this.hasChannelsContainerTarget) {
      addChannelBtn.addEventListener('click', () => this.addChannel())
    }

    // Set up existing remove buttons
    this.setupRemoveButtons()
  }

  addAudience() {
    const template = `
      <div class="bg-gray-50 border border-gray-200 rounded-lg p-4 mb-4">
        <div class="flex items-center justify-between mb-4">
          <h4 class="text-md font-semibold text-theme">New Audience</h4>
          <button type="button" class="text-red-600 hover:text-red-800 text-sm font-medium remove-audience-btn">
            Remove
          </button>
        </div>
        
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label class="peer-disabled:cursor-not-allowed peer-disabled:opacity-70 text-sm font-medium text-gray-700" for="brand_audiences_attributes_${this.audienceIndexValue}_name">
              Audience Name
            </label>
            <input class="flex h-10 w-full bg-background px-3 py-2 text-base ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium file:text-foreground placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 md:text-sm rounded-xl border-2 border-gray-200 focus:border-[#FFC940]" 
                   type="text" 
                   name="brand[audiences_attributes][${this.audienceIndexValue}][name]" 
                   id="brand_audiences_attributes_${this.audienceIndexValue}_name" />
          </div>
          
          <div>
            <label class="peer-disabled:cursor-not-allowed peer-disabled:opacity-70 text-sm font-medium text-gray-700" for="brand_audiences_attributes_${this.audienceIndexValue}_demographic_profile">
              Demographics (JSON)
            </label>
            <textarea class="flex min-h-[80px] w-full bg-background px-3 py-2 text-base ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 md:text-sm rounded-xl border-2 border-gray-200 focus:border-[#FFC940]" 
                      name="brand[audiences_attributes][${this.audienceIndexValue}][demographic_profile]" 
                      id="brand_audiences_attributes_${this.audienceIndexValue}_demographic_profile"
                      placeholder='{"age_range": "25-35", "location": "United States", "interests": ["technology", "lifestyle"]}'></textarea>
          </div>
          
          <div class="md:col-span-2">
            <label class="peer-disabled:cursor-not-allowed peer-disabled:opacity-70 text-sm font-medium text-gray-700" for="brand_audiences_attributes_${this.audienceIndexValue}_interests">
              Interests
            </label>
            <input class="flex h-10 w-full bg-background px-3 py-2 text-base ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium file:text-foreground placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 md:text-sm rounded-xl border-2 border-gray-200 focus:border-[#FFC940]" 
                   type="text" 
                   name="brand[audiences_attributes][${this.audienceIndexValue}][interests]" 
                   id="brand_audiences_attributes_${this.audienceIndexValue}_interests"
                   placeholder="Technology, Fashion, Travel" />
          </div>
        </div>
      </div>
    `

    this.audiencesContainerTarget.insertAdjacentHTML('beforeend', template)
    this.audienceIndexValue++
    this.setupRemoveButtons()
  }

  addProduct() {
    const template = `
      <div class="bg-gray-50 border border-gray-200 rounded-lg p-4 mb-4">
        <div class="flex items-center justify-between mb-4">
          <h4 class="text-md font-semibold text-theme">New Product</h4>
          <button type="button" class="text-red-600 hover:text-red-800 text-sm font-medium remove-product-btn">
            Remove
          </button>
        </div>
        
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label class="peer-disabled:cursor-not-allowed peer-disabled:opacity-70 text-sm font-medium text-gray-700" for="brand_products_attributes_${this.productIndexValue}_name">
              Product Name
            </label>
            <input class="flex h-10 w-full bg-background px-3 py-2 text-base ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium file:text-foreground placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 md:text-sm rounded-xl border-2 border-gray-200 focus:border-[#FFC940]" 
                   type="text" 
                   name="brand[products_attributes][${this.productIndexValue}][name]" 
                   id="brand_products_attributes_${this.productIndexValue}_name" />
          </div>
          
          <div>
            <label class="peer-disabled:cursor-not-allowed peer-disabled:opacity-70 text-sm font-medium text-gray-700" for="brand_products_attributes_${this.productIndexValue}_url">
              Product URL
            </label>
            <input class="flex h-10 w-full bg-background px-3 py-2 text-base ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium file:text-foreground placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 md:text-sm rounded-xl border-2 border-gray-200 focus:border-[#FFC940]" 
                   type="url" 
                   name="brand[products_attributes][${this.productIndexValue}][url]" 
                   id="brand_products_attributes_${this.productIndexValue}_url" />
          </div>
          
          <div class="md:col-span-2">
            <label class="peer-disabled:cursor-not-allowed peer-disabled:opacity-70 text-sm font-medium text-gray-700" for="brand_products_attributes_${this.productIndexValue}_description">
              Description
            </label>
            <textarea class="flex min-h-[80px] w-full bg-background px-3 py-2 text-base ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 md:text-sm rounded-xl border-2 border-gray-200 focus:border-[#FFC940]" 
                      name="brand[products_attributes][${this.productIndexValue}][description]" 
                      id="brand_products_attributes_${this.productIndexValue}_description"></textarea>
          </div>
        </div>
      </div>
    `

    this.productsContainerTarget.insertAdjacentHTML('beforeend', template)
    this.productIndexValue++
    this.setupRemoveButtons()
  }

  addChannel() {
    const template = `
      <div class="bg-gray-50 border border-gray-200 rounded-lg p-4 mb-4">
        <div class="flex items-center justify-between mb-4">
          <h4 class="text-md font-semibold text-theme">New Channel</h4>
          <button type="button" class="text-red-600 hover:text-red-800 text-sm font-medium remove-channel-btn">
            Remove
          </button>
        </div>
        
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <label class="peer-disabled:cursor-not-allowed peer-disabled:opacity-70 text-sm font-medium text-gray-700" for="brand_brand_channels_attributes_${this.channelIndexValue}_platform">
              Platform
            </label>
            <select class="flex h-10 w-full bg-background px-3 py-2 text-base ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 md:text-sm rounded-xl border-2 border-gray-200 focus:border-[#FFC940]" 
                    name="brand[brand_channels_attributes][${this.channelIndexValue}][platform]" 
                    id="brand_brand_channels_attributes_${this.channelIndexValue}_platform">
              <option value="">Select Platform</option>
              <option value="instagram">Instagram</option>
              <option value="tiktok">TikTok</option>
              <option value="youtube">YouTube</option>
              <option value="facebook">Facebook</option>
              <option value="twitter">Twitter</option>
              <option value="linkedin">LinkedIn</option>
            </select>
          </div>
          
          <div>
            <label class="peer-disabled:cursor-not-allowed peer-disabled:opacity-70 text-sm font-medium text-gray-700" for="brand_brand_channels_attributes_${this.channelIndexValue}_handle">
              Handle/Username
            </label>
            <input class="flex h-10 w-full bg-background px-3 py-2 text-base ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium file:text-foreground placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 md:text-sm rounded-xl border-2 border-gray-200 focus:border-[#FFC940]" 
                   type="text" 
                   name="brand[brand_channels_attributes][${this.channelIndexValue}][handle]" 
                   id="brand_brand_channels_attributes_${this.channelIndexValue}_handle"
                   placeholder="@username" />
          </div>
          
          <div>
            <label class="peer-disabled:cursor-not-allowed peer-disabled:opacity-70 text-sm font-medium text-gray-700" for="brand_brand_channels_attributes_${this.channelIndexValue}_priority">
              Priority
            </label>
            <select class="flex h-10 w-full bg-background px-3 py-2 text-base ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 md:text-sm rounded-xl border-2 border-gray-200 focus:border-[#FFC940]" 
                    name="brand[brand_channels_attributes][${this.channelIndexValue}][priority]" 
                    id="brand_brand_channels_attributes_${this.channelIndexValue}_priority">
              <option value="1">High Priority</option>
              <option value="2">Medium Priority</option>
              <option value="3">Low Priority</option>
            </select>
          </div>
        </div>
      </div>
    `

    this.channelsContainerTarget.insertAdjacentHTML('beforeend', template)
    this.channelIndexValue++
    this.setupRemoveButtons()
  }

  setupRemoveButtons() {
    // Audience remove buttons
    document.querySelectorAll('.remove-audience-btn').forEach(btn => {
      btn.replaceWith(btn.cloneNode(true)) // Remove existing listeners
      const newBtn = btn.nextSibling || btn.previousSibling || btn
      newBtn.addEventListener('click', (e) => {
        e.target.closest('.bg-gray-50').remove()
      })
    })

    // Product remove buttons
    document.querySelectorAll('.remove-product-btn').forEach(btn => {
      btn.replaceWith(btn.cloneNode(true))
      const newBtn = btn.nextSibling || btn.previousSibling || btn
      newBtn.addEventListener('click', (e) => {
        e.target.closest('.bg-gray-50').remove()
      })
    })

    // Channel remove buttons
    document.querySelectorAll('.remove-channel-btn').forEach(btn => {
      btn.replaceWith(btn.cloneNode(true))
      const newBtn = btn.nextSibling || btn.previousSibling || btn
      newBtn.addEventListener('click', (e) => {
        e.target.closest('.bg-gray-50').remove()
      })
    })
  }
}