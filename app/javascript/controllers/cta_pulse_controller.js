import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return
    this.timeout = setTimeout(() => this.pulse(), 3000)
  }

  disconnect() {
    if (this.timeout) clearTimeout(this.timeout)
  }

  pulse() {
    this.element.animate([
      { boxShadow: '0 0 0 0 rgba(0,194,255,0.0)' },
      { boxShadow: '0 0 24px 4px rgba(0,194,255,0.35)' },
      { boxShadow: '0 0 0 0 rgba(0,194,255,0.0)' }
    ], { duration: 1600, iterations: 1, easing: 'ease-out' })
  }
}

