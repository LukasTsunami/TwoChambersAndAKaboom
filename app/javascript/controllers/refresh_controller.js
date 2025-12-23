import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    interval: { type: Number, default: 5000 },
    url: String
  }

  connect() {
    this.startRefresh()
  }

  disconnect() {
    this.stopRefresh()
  }

  startRefresh() {
    this.refreshTimer = setInterval(() => {
      this.refresh()
    }, this.intervalValue)
  }

  stopRefresh() {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer)
      this.refreshTimer = null
    }
  }

  isModalOpen() {
    // Check if any modal is visible
    const modals = document.querySelectorAll('[id$="-modal"]')
    for (const modal of modals) {
      if (!modal.classList.contains('hidden')) {
        return true
      }
    }
    return false
  }

  async refresh() {
    // Don't refresh if a modal is open
    if (this.isModalOpen()) {
      return
    }

    if (this.urlValue) {
      try {
        const response = await fetch(this.urlValue, {
          headers: {
            'Accept': 'text/html',
            'X-Requested-With': 'XMLHttpRequest'
          }
        })

        if (response.ok) {
          // Use Turbo to refresh the frame
          Turbo.visit(this.urlValue, { action: 'replace' })
        }
      } catch (error) {
        console.error('Refresh error:', error)
      }
    }
  }
}
