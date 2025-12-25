import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "count"]

  connect() {
    this.update()
  }

  update() {
    // Filtra os checkboxes marcados e conta
    const selectedCount = this.checkboxTargets.filter(checkbox => checkbox.checked).length
    
    // Atualiza o texto do contador
    if (this.hasCountTarget) {
      this.countTarget.textContent = selectedCount
    }
  }
}