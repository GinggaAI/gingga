import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    autoDismiss: Boolean,
    duration: Number
  }

  connect() {
    if (this.autoDismissValue) {
      const duration = this.durationValue || 5000
      this.timeoutId = setTimeout(() => {
        this.dismiss()
      }, duration)
    }
  }

  disconnect() {
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
    }
  }

  dismiss() {
    this.element.style.transition = 'opacity 0.3s ease-out, transform 0.3s ease-out'
    this.element.style.opacity = '0'
    this.element.style.transform = 'translateY(-100%)'
    
    setTimeout(() => {
      if (this.element.parentNode) {
        this.element.parentNode.removeChild(this.element)
      }
    }, 300)
  }
}