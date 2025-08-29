import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    autoDismiss: Boolean,
    duration: Number
  }

  connect() {
    console.log("Toast controller connected!", this.element)
    
    // Always auto-dismiss after 5 seconds
    this.timeoutId = setTimeout(() => {
      console.log("Auto-dismissing toast after 5 seconds")
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
      console.log("Found dismiss button, adding click listener")
      dismissButton.addEventListener('click', (e) => {
        e.preventDefault()
        console.log("Dismiss button clicked!")
        this.dismiss()
      })
    } else {
      console.log("No dismiss button found")
    }
  }

  dismiss() {
    console.log("Dismissing toast...")
    
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
        console.log("Toast removed from DOM")
      }
    }, 300)
  }
}