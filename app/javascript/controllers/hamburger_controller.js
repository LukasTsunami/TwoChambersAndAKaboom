import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.boundClose = this.close.bind(this)
    // Use mousedown instead of click to avoid issues with button clicks
    document.addEventListener("mousedown", this.boundClose)
  }

  disconnect() {
    document.removeEventListener("mousedown", this.boundClose)
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    event.stopImmediatePropagation()
    
    const isHidden = this.menuTarget.classList.contains("hidden")
    
    if (isHidden) {
      this.menuTarget.classList.remove("hidden")
    } else {
      this.menuTarget.classList.add("hidden")
    }
  }

  close(event) {
    // Don't close if clicking inside the menu container
    if (this.element.contains(event.target)) {
      return
    }
    
    this.menuTarget.classList.add("hidden")
  }
}

