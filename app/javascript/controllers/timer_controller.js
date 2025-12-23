import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display"]
  static values = {
    seconds: Number,
    gameId: Number,
    expiredUrl: String
  }

  connect() {
    this.remaining = this.secondsValue
    this.updateDisplay()
    this.startTimer()
  }

  disconnect() {
    this.stopTimer()
  }

  startTimer() {
    this.timer = setInterval(() => {
      this.remaining -= 1

      if (this.remaining <= 0) {
        this.remaining = 0
        this.stopTimer()
        this.onExpired()
      }

      this.updateDisplay()
    }, 1000)
  }

  stopTimer() {
    if (this.timer) {
      clearInterval(this.timer)
      this.timer = null
    }
  }

  updateDisplay() {
    const minutes = Math.floor(this.remaining / 60)
    const seconds = this.remaining % 60
    const display = `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`

    if (this.hasDisplayTarget) {
      this.displayTarget.textContent = display

      // Muda a cor quando estiver acabando
      if (this.remaining <= 30) {
        this.displayTarget.classList.add('text-red-400')
        this.displayTarget.classList.remove('text-white')
      } else if (this.remaining <= 60) {
        this.displayTarget.classList.add('text-amber-400')
        this.displayTarget.classList.remove('text-white')
      }
    }
  }

  async onExpired() {
    if (this.expiredUrlValue) {
      try {
        const response = await fetch(this.expiredUrlValue, {
          method: 'POST',
          headers: {
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
            'Accept': 'text/vnd.turbo-stream.html',
            'Content-Type': 'application/x-www-form-urlencoded'
          }
        })

        // Reload the page to get the new state
        window.location.reload()
      } catch (error) {
        console.error('Error notifying timer expired:', error)
        window.location.reload()
      }
    }
  }
}

