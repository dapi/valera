import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    // Read hash from URL or show first tab
    const hash = window.location.hash.slice(1)
    const index = hash ? this.findTabIndexBySlug(hash) : 0
    this.showTab(index >= 0 ? index : 0)

    // Listen for hash changes (back/forward buttons)
    this.boundHashChange = this.handleHashChange.bind(this)
    window.addEventListener("hashchange", this.boundHashChange)
  }

  disconnect() {
    window.removeEventListener("hashchange", this.boundHashChange)
  }

  switch(event) {
    event.preventDefault()
    event.stopPropagation()
    const index = parseInt(event.currentTarget.dataset.index, 10)
    this.showTab(index)
    this.updateHash(index)
  }

  showTab(index) {
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
