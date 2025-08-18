import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { once: { type: Boolean, default: true } }

  connect() {
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return
    this.element.style.opacity = 0
    this.element.style.transform = 'translateY(8px)'
    this.observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          this.fadeIn()
          if (this.onceValue) this.observer.disconnect()
        }
      })
    }, { threshold: 0.15 })
    this.observer.observe(this.element)
  }

  disconnect() {
    if (this.observer) this.observer.disconnect()
  }

  fadeIn() {
    this.element.style.transition = 'opacity 200ms ease-out, transform 200ms ease-out'
    this.element.style.opacity = 1
    this.element.style.transform = 'translateY(0)'
  }
}

