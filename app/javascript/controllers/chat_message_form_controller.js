import { Controller } from "@hotwired/stimulus"

// Handles chat message form submission and input clearing
// Submits form on Enter key and clears input after successful submission
export default class extends Controller {
  static targets = ["input"]

  connect() {
    // Listen for turbo:submit-end to clear input after successful submission
    this.element.addEventListener("turbo:submit-end", this.handleSubmitEnd.bind(this))
  }

  disconnect() {
    this.element.removeEventListener("turbo:submit-end", this.handleSubmitEnd.bind(this))
  }

  // Submit form (called on Enter keypress via data-action)
  submit(event) {
    // Only submit on Enter without Shift (allow Shift+Enter for newlines in future textarea)
    if (event.shiftKey) return

    event.preventDefault()
    this.element.requestSubmit()
  }

  // Clear input after successful form submission
  handleSubmitEnd(event) {
    if (event.detail.success) {
      const input = this.element.querySelector("input[name='text']")
      if (input) {
        input.value = ""
        input.focus()
      }
    }
  }
}
