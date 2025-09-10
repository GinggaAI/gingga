import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    type: String, 
    duration: Number 
  }

  connect() {
    // Default duration based on type
    const defaultDuration = this.typeValue === "error" ? 10000 : 8000
    const duration = this.hasDurationValue ? this.durationValue : defaultDuration
    
    // Auto-hide the flash message after specified duration
    if (duration > 0) {
      this.timeout = setTimeout(() => {
        this.dismiss()
      }, duration)
    }
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  dismiss() {
    // Clear any pending timeout
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
    
    // Add fade out animation
    this.element.style.transition = "opacity 0.3s ease-out"
    this.element.style.opacity = "0"
    
    // Remove element after animation
    setTimeout(() => {
      if (this.element && this.element.parentNode) {
        this.element.remove()
      }
    }, 300)
  }
}