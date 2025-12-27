import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel", "conditional"]

  connect() {
    this.initializeTabs()

    // Listen for hash changes (back/forward buttons)
    this.boundHashChange = this.handleHashChange.bind(this)
    window.addEventListener("hashchange", this.boundHashChange)

    // Re-initialize on Turbo render to fix styling issues
    this.boundTurboRender = this.initializeTabs.bind(this)
    document.addEventListener("turbo:render", this.boundTurboRender)
  }

  initializeTabs() {
    // Read hash from URL or show first tab
    const hash = window.location.hash.slice(1)
    const index = hash ? this.findTabIndexBySlug(hash) : 0
    this.showTab(index >= 0 ? index : 0)

    // Remove loading class to reveal content (prevents flash of wrong tab)
    this.element.classList.remove("admin-tabs--loading")
  }

  disconnect() {
    window.removeEventListener("hashchange", this.boundHashChange)
    document.removeEventListener("turbo:render", this.boundTurboRender)
  }

  switch(event) {
    event.preventDefault()
    event.stopPropagation()
    const index = parseInt(event.currentTarget.dataset.index, 10)
    this.showTab(index)
    this.updateHash(index)
  }

  showTab(index) {
    const activeSlug = this.tabTargets[index]?.dataset.slug

    this.tabTargets.forEach((tab, i) => {
      if (i === index) {
        tab.classList.add("admin-tabs__button--active")
      } else {
        tab.classList.remove("admin-tabs__button--active")
      }
    })

    this.panelTargets.forEach((panel, i) => {
      panel.hidden = (i !== index)
    })

    // Show/hide conditional elements based on active tab
    this.conditionalTargets.forEach((el) => {
      const showForTab = el.dataset.showForTab
      el.hidden = (showForTab !== activeSlug)
    })
  }

  updateHash(index) {
    const tab = this.tabTargets[index]
    if (tab && tab.dataset.slug) {
      history.replaceState(null, null, `#${tab.dataset.slug}`)
    }
  }

  findTabIndexBySlug(slug) {
    return this.tabTargets.findIndex(tab => tab.dataset.slug === slug)
  }

  handleHashChange() {
    const hash = window.location.hash.slice(1)
    if (hash) {
      const index = this.findTabIndexBySlug(hash)
      if (index >= 0) {
        this.showTab(index)
      }
    }
  }
}
