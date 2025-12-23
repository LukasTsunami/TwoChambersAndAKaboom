import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    interval: { type: Number, default: 5000 },
    url: String
  }

  connect() {
    this.hasPendingUpdate = false
    this.startRefresh()
  }

  disconnect() {
    this.stopRefresh()
    this.removeNotification()
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
    
    // Check if hamburger menu is open
    const hamburgerMenu = document.querySelector('[data-hamburger-target="menu"]')
    if (hamburgerMenu && !hamburgerMenu.classList.contains('hidden')) {
      return true
    }
    
    return false
  }

  showUpdateNotification() {
    // Don't show if already showing
    if (document.getElementById('update-notification')) {
      return
    }

    const notification = document.createElement('div')
    notification.id = 'update-notification'
    notification.className = 'fixed top-4 left-4 right-4 z-40 bg-amber-500/90 backdrop-blur-sm text-slate-900 px-4 py-3 rounded-xl text-center font-semibold flex items-center justify-center gap-2 slide-up'
    notification.innerHTML = `
      <svg class="w-5 h-5 animate-pulse" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
      </svg>
      <span>Há atualizações! Feche o modal para ver.</span>
    `

    document.body.appendChild(notification)
    this.hasPendingUpdate = true

    // Start checking if modal is closed
    this.checkModalClosed()
  }

  removeNotification() {
    const notification = document.getElementById('update-notification')
    if (notification) {
      notification.remove()
    }
    this.hasPendingUpdate = false
  }

  checkModalClosed() {
    if (!this.hasPendingUpdate) return

    const checkInterval = setInterval(() => {
      if (!this.isModalOpen()) {
        clearInterval(checkInterval)
        this.removeNotification()
        // Do the refresh now
        if (this.urlValue) {
          Turbo.visit(this.urlValue, { action: 'replace' })
        }
      }
    }, 500)

    // Stop checking after 30 seconds
    setTimeout(() => {
      clearInterval(checkInterval)
    }, 30000)
  }

  async refresh() {
    // If modal is open, show notification instead of refreshing
    if (this.isModalOpen()) {
      this.showUpdateNotification()
      return
    }

    // If there's a pending update and modal is now closed, it will be handled by checkModalClosed
    if (this.hasPendingUpdate) {
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
