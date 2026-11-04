import { Controller } from "@hotwired/stimulus"

// Fragments never reach HTTP access logs or referrers. Tokens are submitted
// only in filtered POST bodies, then removed from the browser address bar.
export default class extends Controller {
  static targets = ["token", "status"]
  static values = { autoSubmit: Boolean }

  connect() {
    const token = new URLSearchParams(window.location.hash.slice(1)).get("token")
    if (token) {
      this.tokenTarget.value = token
      window.history.replaceState(null, "", window.location.pathname)
      if (this.autoSubmitValue) this.element.requestSubmit()
    } else if (!this.tokenTarget.value && this.hasStatusTarget) {
      this.statusTarget.textContent = "Откройте полную ссылку из письма или приглашения."
    }
  }
}
