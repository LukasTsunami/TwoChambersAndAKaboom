import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["createBtn", "loginBtn", "modeInput", "pinHint"]
  static values = {
    startLogin: { type: Boolean, default: false }
  }

  connect() {
    // Start in login mode if specified
    if (this.startLoginValue) {
      this.showLogin()
    } else {
      this.showCreate()
    }
  }

  showCreate() {
    // Update buttons
    this.createBtnTarget.classList.add("bg-amber-500", "text-slate-900")
    this.createBtnTarget.classList.remove("text-slate-400", "hover:text-white")

    this.loginBtnTarget.classList.remove("bg-amber-500", "text-slate-900")
    this.loginBtnTarget.classList.add("text-slate-400", "hover:text-white")

    // Update mode
    this.modeInputTarget.value = "create"

    // Update hint
    if (this.hasPinHintTarget) {
      this.pinHintTarget.textContent = "Crie um PIN para acessar sua conta depois"
    }
  }

  showLogin() {
    // Update buttons
    this.loginBtnTarget.classList.add("bg-amber-500", "text-slate-900")
    this.loginBtnTarget.classList.remove("text-slate-400", "hover:text-white")

    this.createBtnTarget.classList.remove("bg-amber-500", "text-slate-900")
    this.createBtnTarget.classList.add("text-slate-400", "hover:text-white")

    // Update mode
    this.modeInputTarget.value = "login"

    // Update hint
    if (this.hasPinHintTarget) {
      this.pinHintTarget.textContent = "Digite o PIN que você cadastrou"
    }
  }
}
