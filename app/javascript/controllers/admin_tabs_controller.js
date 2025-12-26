import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = { index: { type: Number, default: 0 } }

  connect() {
    this.showTab(this.indexValue)
  }

  switch(event) {
    event.preventDefault()
    const index = parseInt(event.currentTarget.dataset.index)
    this.showTab(index)
  }

  showTab(index) {
    this.tabTargets.forEach((tab, i) => {
      tab.classList.toggle("active", i === index)
    })
    this.panelTargets.forEach((panel, i) => {
      panel.hidden = i !== index
    })
  }
}
