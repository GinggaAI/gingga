import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  change(event) {
    if (event.target.value) {
      window.location.href = `/my-brand?brand_id=${event.target.value}`
    }
  }
}