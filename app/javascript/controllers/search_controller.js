import { Controller } from "@hotwired/stimulus"

// Stimulus controller for debounced search
// Automatically submits form after user stops typing
export default class extends Controller {
  static values = {
    delay: { type: Number, default: 300 }
  }

  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.element.requestSubmit()
    }, this.delayValue)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
