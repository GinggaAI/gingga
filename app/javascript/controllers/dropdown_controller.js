import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "chevron"]

  connect() {
    this.close = this.close.bind(this)
  }

  toggle() {
    if (this.menuTarget.classList.contains("hidden")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.menuTarget.classList.remove("hidden")
    if (this.hasChevronTarget) {
      this.chevronTarget.style.transform = "rotate(180deg)"
    }
    document.addEventListener("click", this.close)
  }

  close(event) {
    if (event && this.element.contains(event.target)) {
      return
    }

    this.menuTarget.classList.add("hidden")
    if (this.hasChevronTarget) {
      this.chevronTarget.style.transform = "rotate(0deg)"
    }
    document.removeEventListener("click", this.close)
  }

  selectBrand(event) {
    const brandId = event.currentTarget.getAttribute('data-brand-option')

    // Get current locale from URL or default to 'en'
    const currentPath = window.location.pathname
    const localeMatch = currentPath.match(/^\/(en|es)/)
    const locale = localeMatch ? localeMatch[1] : 'en'
    const switchUrl = `/${locale}/switch_brand`

    console.log('Switching brand:', brandId, 'to URL:', switchUrl)

    // Make request to switch brand
    fetch(switchUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').getAttribute('content')
      },
      body: JSON.stringify({
        brand_id: brandId
      })
    }).then(response => {
      console.log('Switch response:', response.status)
      if (response.ok) {
        window.location.reload()
      } else {
        return response.json().then(data => {
          console.error('Brand switch failed:', data)
          alert('Error switching brand: ' + (data.error || 'Unknown error'))
        })
      }
    }).catch(error => {
      console.error('Error switching brand:', error)
      alert('Error switching brand: ' + error.message)
    })
  }

  disconnect() {
    document.removeEventListener("click", this.close)
  }
}