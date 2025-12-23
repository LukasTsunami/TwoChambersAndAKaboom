import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "step1", "step2", "step3",
    "nameInput", "pinInput",
    "pinTitle", "pinHint",
    "backBtn", "stepIndicator",
    "modeInput", "displayName",
    "normalActions", "activeGameAction", "gameCodeDisplay"
  ]

  static values = {
    currentStep: { type: Number, default: 1 },
    mode: { type: String, default: "create" }, // "create" ou "login"
    prefillName: String,
    prefillMode: String
  }

  connect() {
    // Se veio com nome preenchido (usuário existente), pular para step 2
    if (this.prefillNameValue && this.prefillModeValue === "login") {
      this.nameInputTarget.value = this.prefillNameValue
      this.modeValue = "login"
      this.goToStep(2)
    } else {
      this.goToStep(1)
    }
  }

  // Step 1: Verificar nome e ir para step 2
  async checkName(event) {
    event.preventDefault()

    const name = this.nameInputTarget.value.trim()
    if (!name) {
      this.showError("Digite seu nome")
      return
    }

    // Verificar se o nome já existe
    try {
      const response = await fetch(`/players/check_name?name=${encodeURIComponent(name)}`)
      const data = await response.json()

      if (data.exists) {
        this.modeValue = "login"
      } else {
        this.modeValue = "create"
      }

      this.goToStep(2)
    } catch (error) {
      // Se falhar a verificação, assume novo usuário
      this.modeValue = "create"
      this.goToStep(2)
    }
  }

  // Step 2: Verificar PIN e ir para step 3
  async checkPin(event) {
    event.preventDefault()

    const pin = this.pinInputTarget.value.trim()
    if (!pin || !/^\d{3}$/.test(pin)) {
      this.showError("PIN deve ter exatamente 3 dígitos")
      return
    }

    const name = this.nameInputTarget.value.trim()

    // Validar PIN se for login
    if (this.modeValue === "login") {
      try {
        const response = await fetch('/players/validate_pin', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
          },
          body: JSON.stringify({ name, pin })
        })
        const data = await response.json()

        if (!data.valid) {
          this.showError(data.error || "PIN incorreto")
          return
        }

        this.hasActiveGame = data.has_active_game
        this.gameCode = data.game_code
      } catch (error) {
        console.error('Erro ao validar PIN:', error)
      }
    } else {
      this.hasActiveGame = false
    }

    this.goToStep(3)
  }

  // Voltar um step
  goBack() {
    if (this.currentStepValue > 1) {
      this.goToStep(this.currentStepValue - 1)
    }
  }

  // Ir para um step específico
  goToStep(step) {
    this.currentStepValue = step

    // Esconder todos os steps
    this.step1Target.classList.add("hidden")
    this.step2Target.classList.add("hidden")
    this.step3Target.classList.add("hidden")

    // Mostrar o step atual
    if (step === 1) {
      this.step1Target.classList.remove("hidden")
      this.backBtnTarget.classList.add("hidden")
      this.nameInputTarget.focus()
    } else if (step === 2) {
      this.step2Target.classList.remove("hidden")
      this.backBtnTarget.classList.remove("hidden")
      this.updatePinMessages()
      this.pinInputTarget.focus()
    } else if (step === 3) {
      this.step3Target.classList.remove("hidden")
      this.backBtnTarget.classList.remove("hidden")
      this.modeInputTarget.value = this.modeValue
      this.displayNameTarget.textContent = this.nameInputTarget.value

      // Mostrar botões corretos baseado no jogo ativo
      if (this.hasActiveGame) {
        this.normalActionsTarget.classList.add("hidden")
        this.activeGameActionTarget.classList.remove("hidden")
        if (this.hasGameCodeDisplayTarget) {
          this.gameCodeDisplayTarget.textContent = this.gameCode
        }
      } else {
        this.normalActionsTarget.classList.remove("hidden")
        this.activeGameActionTarget.classList.add("hidden")
      }
    }

    // Atualizar indicadores
    this.updateStepIndicators()
  }

  updatePinMessages() {
    if (this.modeValue === "login") {
      this.pinTitleTarget.textContent = "Digite seu PIN"
      this.pinHintTarget.innerHTML = `<span class="text-blue-400">👋 Bem-vindo de volta!</span> Digite o PIN que você cadastrou.`
    } else {
      this.pinTitleTarget.textContent = "Crie um PIN"
      this.pinHintTarget.innerHTML = `<span class="text-green-400">✨ Novo jogador!</span> Crie um PIN de 3 dígitos para acessar sua conta depois.`
    }
  }

  updateStepIndicators() {
    const indicators = this.stepIndicatorTargets
    indicators.forEach((indicator, index) => {
      const stepNum = index + 1
      if (stepNum < this.currentStepValue) {
        // Completed
        indicator.classList.remove("bg-slate-600", "bg-amber-500")
        indicator.classList.add("bg-green-500")
        indicator.innerHTML = "✓"
      } else if (stepNum === this.currentStepValue) {
        // Current
        indicator.classList.remove("bg-slate-600", "bg-green-500")
        indicator.classList.add("bg-amber-500")
        indicator.innerHTML = stepNum
      } else {
        // Future
        indicator.classList.remove("bg-amber-500", "bg-green-500")
        indicator.classList.add("bg-slate-600")
        indicator.innerHTML = stepNum
      }
    })
  }

  showError(message) {
    // Pode implementar uma notificação mais elaborada
    alert(message)
  }
}

