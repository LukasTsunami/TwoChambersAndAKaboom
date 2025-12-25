class PlayersController < ApplicationController
  before_action :require_player!, only: [:update]

  # GET /players/check_name
  def check_name
    name_query = player_parameters[:name]
    exists = Player.name_exists?(name_query)
    
    render json: { exists: exists }
  end

  # POST /players/validate_pin
  def validate_pin
    name_query = player_parameters[:name]
    pin_attempt = player_parameters[:pin]

    player = Player.find_by(name: name_query)

    if player.nil?
      render json: { valid: true, new_player: true, has_active_game: false }
    elsif player.pin == pin_attempt
      has_game = player.game.present?
      game_code = player.game&.code
      
      render json: { 
        valid: true, 
        new_player: false, 
        has_active_game: has_game, 
        game_code: game_code 
      }
    else
      render json: { valid: false, error: "PIN incorreto" }
    end
  end

  # POST /players
  def create
    # Validações básicas de entrada antes de prosseguir
    return unless inputs_valid?

    if processing_login_mode?
      process_login
    else
      process_registration
    end
  end

  # PATCH/PUT /players/:id
  def update
    new_name = player_parameters[:name]

    if new_name.blank?
      redirect_back fallback_location: root_path, alert: 'Nome não pode estar vazio.'
      return
    end

    if name_taken_by_others?(new_name)
      redirect_back fallback_location: root_path, alert: 'Este nome já está em uso.'
      return
    end

    current_player.update!(name: new_name)
    redirect_back fallback_location: root_path, notice: 'Nome atualizado com sucesso!'
  end

  private

  # --- Strong Parameters & Sanitization ---

  def player_parameters
    # Permite apenas name e pin, e já remove espaços em branco
    sanitized_params = params.permit(:name, :pin)
    sanitized_params[:name] = sanitized_params[:name]&.strip
    sanitized_params[:pin]  = sanitized_params[:pin]&.strip
    sanitized_params
  end

  # Parâmetros de fluxo (não salvos no banco, mas controlam a lógica)
  def flow_parameters
    params.permit(:mode, :action_type)
  end

  # --- Helper Methods for Validation ---

  def inputs_valid?
    if player_parameters[:name].blank?
      redirect_to root_path, alert: 'Nome não pode estar vazio.'
      return false
    end

    pin = player_parameters[:pin]
    if pin.blank? || !pin.match?(/\A\d{3}\z/)
      redirect_to root_path, alert: 'PIN deve ter exatamente 3 dígitos numéricos.'
      return false
    end

    true
  end

  def name_taken_by_others?(name)
    Player.where.not(id: current_player.id).exists?(name: name)
  end

  def processing_login_mode?
    flow_parameters[:mode] == 'login'
  end

  # --- Business Logic Flows ---

  def process_login
    player = Player.authenticate(player_parameters[:name], player_parameters[:pin])

    if player.nil?
      redirect_to root_path, alert: 'Nome ou PIN incorreto.'
      return
    end

    establish_session(player)
  end

  def process_registration
    if Player.name_exists?(player_parameters[:name])
      # Se tentar registrar mas nome já existe, redireciona para login mantendo o contexto
      redirect_to root_path(
        name: player_parameters[:name], 
        mode: 'login', 
        action_type: flow_parameters[:action_type]
      ), alert: "Este usuário já existe! Informe o PIN para entrar."
      return
    end

    new_player = Player.new(player_parameters)

    if new_player.save
      establish_session(new_player)
    else
      redirect_to root_path, alert: new_player.errors.full_messages.join(', ')
    end
  end

  def establish_session(player)
    session[:player_id] = player.id
    redirect_after_authentication(player)
  end

  def redirect_after_authentication(player)
    action_type = flow_parameters[:action_type]
    has_active_game = player.game.present?

    # Prioridade 1: Jogador já tem jogo ativo (Rejoin ou prevenção de fuga)
    if has_active_game
      redirect_to game_path(player.game)
      return
    end

    # Prioridade 2: Fluxos de Criação ou Entrada
    case action_type
    when 'create'
      redirect_to new_game_path
    else # 'join' ou padrão
      redirect_to join_games_path
    end
  end
end