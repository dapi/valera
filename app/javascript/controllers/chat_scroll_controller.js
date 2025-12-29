import { Controller } from "@hotwired/stimulus"

// Auto-scrolls chat to the bottom when connected
// Attaches to the chat messages container and scrolls parent to show latest messages
export default class extends Controller {
  connect() {
    // Store animation frame ID for cleanup
    this.animationFrameId = requestAnimationFrame(() => {
      this.scrollToBottom()
    })
  }

  disconnect() {
    // Cancel pending animation frame to prevent memory leaks
    if (this.animationFrameId) {
      cancelAnimationFrame(this.animationFrameId)
      this.animationFrameId = null
    }
  }

  scrollToBottom() {
    // Find the scrollable parent (the overflow-y-auto container)
    const scrollableParent = this.element.closest('[data-scroll-container]') ||
                             this.element.closest('.overflow-y-auto')

    if (!scrollableParent) {
      console.warn('chat_scroll_controller: scrollable parent not found')
      return
    }

    scrollableParent.scrollTop = scrollableParent.scrollHeight
  }
}
