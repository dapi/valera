import { Controller } from "@hotwired/stimulus"

/**
 * Infinite scroll controller for chat list sidebar
 *
 * Handles loading more chats when user clicks "Load more" button
 * or when the trigger element approaches the viewport (preloads 100px early).
 *
 * Usage:
 *   data-controller="infinite-scroll"
 *   data-infinite-scroll-url-value="/chats"
 *   data-infinite-scroll-page-value="1"
 *   data-infinite-scroll-total-pages-value="5"
 *
 * Targets:
 *   - trigger: container with load more button (will be replaced)
 *   - button: the load more button
 *   - spinner: loading spinner (hidden by default)
 *   - error: error message container (hidden by default)
 */
export default class extends Controller {
  static targets = ["trigger", "button", "spinner", "error"]
  static values = {
    url: String,
    page: Number,
    totalPages: Number,
    loading: { type: Boolean, default: false },
    errorText: { type: String, default: "Ошибка загрузки. Повторить?" }
  }

  connect() {
    this.setupIntersectionObserver()
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  setupIntersectionObserver() {
    if (!this.hasTriggerTarget) return

    this.observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting && !this.loadingValue) {
            this.loadMore()
          }
        })
      },
      {
        root: this.element,
        rootMargin: "100px",
        threshold: 0.1
      }
    )

    this.observer.observe(this.triggerTarget)
  }

  async loadMore() {
    if (this.loadingValue) return
    if (this.pageValue >= this.totalPagesValue) return

    this.loadingValue = true
    this.showSpinner()
    this.hideError()

    const nextPage = this.pageValue + 1
    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set("page", nextPage)

    // Preserve current sort parameter
    const currentSort = new URLSearchParams(window.location.search).get("sort")
    if (currentSort) {
      url.searchParams.set("sort", currentSort)
    }

    try {
      const response = await fetch(url, {
        headers: {
          "Accept": "text/html",
          "X-Requested-With": "XMLHttpRequest",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
        }
      })

      // Handle authentication errors - redirect to login
      if (response.status === 401 || response.status === 403) {
        window.location.href = "/session/new"
        return
      }

      if (!response.ok) throw new Error(`HTTP ${response.status}`)

      const html = await response.text()
      this.appendChats(html)
      this.pageValue = nextPage

      // Remove trigger if no more pages
      if (nextPage >= this.totalPagesValue) {
        this.removeTrigger()
      }
    } catch (error) {
      console.error("Failed to load more chats:", error)
      this.showError()
    } finally {
      this.loadingValue = false
    }
  }

  appendChats(html) {
    // Parse the HTML and append chat items before the trigger
    const template = document.createElement("template")
    template.innerHTML = html.trim()

    const fragment = template.content
    const chatItems = fragment.querySelectorAll("[id^='chat_list_item_']")

    if (this.hasTriggerTarget) {
      chatItems.forEach((item) => {
        this.triggerTarget.before(item)
      })
    }

    this.hideSpinner()
  }

  removeTrigger() {
    if (this.hasTriggerTarget) {
      this.triggerTarget.remove()
    }
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  showSpinner() {
    if (this.hasButtonTarget) this.buttonTarget.classList.add("hidden")
    if (this.hasSpinnerTarget) this.spinnerTarget.classList.remove("hidden")
  }

  hideSpinner() {
    if (this.hasButtonTarget) this.buttonTarget.classList.remove("hidden")
    if (this.hasSpinnerTarget) this.spinnerTarget.classList.add("hidden")
  }

  showError() {
    this.hideSpinner()
    if (this.hasErrorTarget) {
      this.errorTarget.classList.remove("hidden")
    } else if (this.hasButtonTarget) {
      // Fallback: change button text to error state
      this.buttonTarget.textContent = this.errorTextValue
      this.buttonTarget.classList.add("text-red-600")
      this.buttonTarget.classList.remove("text-blue-600", "hidden")
    }
  }

  hideError() {
    if (this.hasErrorTarget) {
      this.errorTarget.classList.add("hidden")
    }
    if (this.hasButtonTarget) {
      this.buttonTarget.classList.remove("text-red-600")
      this.buttonTarget.classList.add("text-blue-600")
    }
  }
}
