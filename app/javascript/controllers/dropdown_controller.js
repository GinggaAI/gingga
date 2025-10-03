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


  disconnect() {
    document.removeEventListener("click", this.close)
  }
}