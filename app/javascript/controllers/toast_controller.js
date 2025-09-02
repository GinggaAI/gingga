import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    autoDismiss: Boolean,
    duration: Number
  }

  connect() {
    // Always auto-dismiss after 5 seconds
    this.timeoutId = setTimeout(() => {
      this.dismiss()
    }, 5000)
    
    // Also set up manual dismiss
    this.setupManualDismiss()
  }

  disconnect() {
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
    }
  }

  setupManualDismiss() {
    const dismissButton = this.element.querySelector('.ui-toast__dismiss')
    if (dismissButton) {
      dismissButton.addEventListener('click', (e) => {
        e.preventDefault()
        this.dismiss()
      })
    }
  }

  dismiss() {
    // Clear the auto-dismiss timeout
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
    }
    
    // Add fade-out animation
    this.element.style.transition = 'opacity 0.3s ease-out, transform 0.3s ease-out'
    this.element.style.opacity = '0'
    this.element.style.transform = 'translateY(-10px)'
    
    // Remove element after animation
    setTimeout(() => {
      if (this.element && this.element.parentNode) {
        this.element.parentNode.removeChild(this.element)
      }
    }, 300)
  }
}