import { Controller } from "@hotwired/stimulus"

// UTM tracking controller
// Captures UTM params from URL, saves to cookies, populates form fields
export default class extends Controller {
  static targets = ["source", "medium", "campaign"]

  static UTM_PARAMS = ["utm_source", "utm_medium", "utm_campaign"]
  static COOKIE_EXPIRY_DAYS = 30

  connect() {
    this.captureUtmParams()
    this.populateFormFields()
  }

  // Capture UTM params from URL and save to cookies
  captureUtmParams() {
    const urlParams = new URLSearchParams(window.location.search)

    this.constructor.UTM_PARAMS.forEach(param => {
      const value = urlParams.get(param)
      if (value) {
        this.setCookie(param, value, this.constructor.COOKIE_EXPIRY_DAYS)
      }
    })
  }

  // Populate form fields from URL params or cookies
  populateFormFields() {
    const urlParams = new URLSearchParams(window.location.search)

    if (this.hasSourceTarget) {
      this.sourceTarget.value = urlParams.get("utm_source") || this.getCookie("utm_source") || ""
    }
    if (this.hasMediumTarget) {
      this.mediumTarget.value = urlParams.get("utm_medium") || this.getCookie("utm_medium") || ""
    }
    if (this.hasCampaignTarget) {
      this.campaignTarget.value = urlParams.get("utm_campaign") || this.getCookie("utm_campaign") || ""
    }
  }

  setCookie(name, value, days) {
    const date = new Date()
    date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000))
    const expires = `expires=${date.toUTCString()}`
    document.cookie = `${name}=${encodeURIComponent(value)};${expires};path=/;SameSite=Lax`
  }

  getCookie(name) {
    const nameEQ = `${name}=`
    const cookies = document.cookie.split(";")
    for (let cookie of cookies) {
      cookie = cookie.trim()
      if (cookie.indexOf(nameEQ) === 0) {
        return decodeURIComponent(cookie.substring(nameEQ.length))
      }
    }
    return null
  }
}
