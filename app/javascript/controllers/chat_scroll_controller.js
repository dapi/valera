import { Controller } from "@hotwired/stimulus"

// Auto-scrolls chat to the bottom when connected
export default class extends Controller {
  connect() {
    // Wait for DOM to be fully rendered before scrolling
    requestAnimationFrame(() => {
      this.scrollToBottom()
    })
  }

  scrollToBottom() {
    // Find the scrollable parent (the overflow-y-auto container)
    const scrollableParent = this.element.closest('.overflow-y-auto')
    if (scrollableParent) {
      scrollableParent.scrollTop = scrollableParent.scrollHeight
    }
  }
}
