import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    this.showTab(0)
  }

  switch(event) {
    event.preventDefault()
    event.stopPropagation()
    const index = parseInt(event.currentTarget.dataset.index, 10)
    this.showTab(index)
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
}
