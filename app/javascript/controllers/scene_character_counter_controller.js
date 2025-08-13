import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["counter"]

  connect() {
    this.updateCounter()
  }

  updateCounter() {
    const textarea = this.element.querySelector('textarea')
    if (textarea && this.counterTarget) {
      const currentLength = textarea.value.length
      const maxLength = textarea.getAttribute('maxlength') || 500
      this.counterTarget.textContent = `${currentLength}/${maxLength}`
      
      // Update styling based on character count
      if (currentLength > maxLength * 0.9) {
        this.counterTarget.style.color = 'var(--orange)'
      } else if (currentLength > maxLength * 0.8) {
        this.counterTarget.style.color = 'var(--primary)'
      } else {
        this.counterTarget.style.color = 'var(--muted)'
      }
    }
  }
}