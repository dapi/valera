import { Controller } from "@hotwired/stimulus"

// Displays a countdown timer that updates every second
// Used for showing remaining takeover timeout in chat status
//
// Usage:
//   <span data-controller="countdown" data-countdown-seconds-value="1800">
//     (30м)
//   </span>
export default class extends Controller {
  static values = {
    seconds: Number
  }

  connect() {
    this.remainingSeconds = this.secondsValue
    this.updateDisplay()
    this.startTimer()
  }

  disconnect() {
    this.stopTimer()
  }

  startTimer() {
    this.intervalId = setInterval(() => {
      this.remainingSeconds -= 1

      if (this.remainingSeconds <= 0) {
        this.stopTimer()
        // Timer expired - page will be updated via Turbo Stream from server
        this.element.textContent = "(0м)"
        return
      }

      this.updateDisplay()
    }, 1000)
  }

  stopTimer() {
    if (this.intervalId) {
      clearInterval(this.intervalId)
      this.intervalId = null
    }
  }

  updateDisplay() {
    const minutes = Math.floor(this.remainingSeconds / 60)
    const seconds = this.remainingSeconds % 60

    if (minutes > 0) {
      this.element.textContent = `(${minutes}м ${seconds}с)`
    } else {
      this.element.textContent = `(${seconds}с)`
    }
  }
}
