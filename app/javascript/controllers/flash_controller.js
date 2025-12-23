import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["message"]

  connect() {
    // Auto-hide after 4 seconds
    setTimeout(() => {
      this.dismiss()
    }, 4000)
  }

  dismiss() {
    this.element.classList.add('opacity-0', 'translate-y-[-20px]')
    this.element.style.transition = 'all 0.3s ease-out'

    setTimeout(() => {
      this.element.remove()
    }, 300)
  }
}

