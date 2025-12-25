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

    // Já que clico num elemento x posicionado absolute na página, preciso procurar o container
    // de modal mais próximo na dom pra fechar
    const modal = event.currentTarget.closest("[id$='-modal']")

    if (modal) {
      modal.classList.add("hidden")
      document.body.style.overflow = ""
    }
  }

  closeBackground(event) {
    // Só fecha ao clicar no lugar certo
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

