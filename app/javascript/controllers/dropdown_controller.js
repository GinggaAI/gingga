import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.close = this.close.bind(this)
  }

  toggle() {
    if (this.menuTarget.style.display === "none" || this.menuTarget.style.display === "") {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.menuTarget.style.display = "block"
    document.addEventListener("click", this.close)
  }

  close(event) {
    if (event && this.element.contains(event.target)) {
      return
    }
    
    this.menuTarget.style.display = "none"
    document.removeEventListener("click", this.close)
  }

  disconnect() {
    document.removeEventListener("click", this.close)
  }
}