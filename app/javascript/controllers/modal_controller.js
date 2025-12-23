import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  open(event) {
    event.preventDefault()
    event.stopPropagation()

    const modalId = event.currentTarget.dataset.modalId
    const modal = document.getElementById(modalId)

    if (modal) {
      modal.classList.remove("hidden")
      document.body.style.overflow = "hidden"
    }
  }

  close(event) {
    event.preventDefault()
    event.stopPropagation()

    // Find the closest modal container
    const modal = event.currentTarget.closest("[id$='-modal']")

    if (modal) {
      modal.classList.add("hidden")
      document.body.style.overflow = ""
    }
  }

  closeBackground(event) {
    // Only close if clicking the background itself, not the content
    if (event.target === event.currentTarget) {
      event.preventDefault()
      event.stopPropagation()

      const modal = event.currentTarget.closest("[id$='-modal']")
      if (modal) {
        modal.classList.add("hidden")
        document.body.style.overflow = ""
      }
    }
  }
}

