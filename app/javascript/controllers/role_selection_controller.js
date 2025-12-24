import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modeSelect", "manualSection"]

  connect() {
    this.toggleManualSelection() // Roda ao carregar a página
  }

  toggleManualSelection() {
    // Se o valor do select for 'manual', mostra a div, senão esconde
    if (this.modeSelectTarget.value === 'manual') {
      this.manualSectionTarget.classList.remove('hidden')
    } else {
      this.manualSectionTarget.classList.add('hidden')
    }
  }
}