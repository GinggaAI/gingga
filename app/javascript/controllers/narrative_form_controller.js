import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["categorySelect", "formatSelect"]
  static values = { 
    categoriesUrl: String,
    formatsUrl: String
  }

  connect() {
    this.loadCategories()
    this.loadFormats()
  }

  async loadCategories() {
    try {
      const response = await fetch(this.categoriesUrlValue, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
      
      if (response.ok) {
        const data = await response.json()
        this.populateSelect(this.categorySelectTarget, data.categories)
      }
    } catch (error) {
      console.error('Failed to load categories:', error)
    }
  }

  async loadFormats() {
    try {
      const response = await fetch(this.formatsUrlValue, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
      
      if (response.ok) {
        const data = await response.json()
        this.populateSelect(this.formatSelectTarget, data.formats, 'description')
      }
    } catch (error) {
      console.error('Failed to load formats:', error)
    }
  }

  populateSelect(selectElement, options, descriptionKey = null) {
    // Clear existing options except the first placeholder
    while (selectElement.children.length > 1) {
      selectElement.removeChild(selectElement.lastChild)
    }

    // Add new options
    options.forEach(option => {
      const optionElement = document.createElement('option')
      optionElement.value = option.id
      optionElement.textContent = option.name
      
      if (descriptionKey && option[descriptionKey]) {
        optionElement.title = option[descriptionKey]
      }
      
      selectElement.appendChild(optionElement)
    })
  }
}