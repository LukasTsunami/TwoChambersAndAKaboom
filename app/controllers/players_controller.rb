class PlayersController < ApplicationController
  before_action :require_player!, only: [:update]

  def check_name
    name = params[:name].to_s.strip
    exists = Player.name_exists?(name)
    render json: { exists: exists }
  end

  def validate_pin
    name = params[:name].to_s.strip
    pin = params[:pin].to_s.strip

    player = Player.find_by(name: name)

    if player.nil?
      # Novo jogador - PIN será criado
      render json: { valid: true, new_player: true, has_active_game: false }
    elsif player.pin == pin
      # Login válido
      has_game = player.game.present?
      game_code = player.game&.code
      render json: { valid: true, new_player: false, has_active_game: has_game, game_code: game_code }
    else
      # PIN incorreto
      render json: { valid: false, error: "PIN incorreto" }
    end
  end

  def create
    name = params[:name].to_s.strip
    pin = params[:pin].to_s.strip
    mode = params[:mode] # 'create' or 'login'

    if name.blank?
      redirect_to root_path, alert: 'Nome não pode estar vazio.'
      return
    end

    if pin.blank? || !pin.match?(/\A\d{3}\z/)
      redirect_to root_path, alert: 'PIN deve ter exatamente 3 dígitos numéricos.'
      return
    end

    if mode == 'login'
      # Tentar fazer login
      player = Player.authenticate(name, pin)

      if player.nil?
        redirect_to root_path, alert: 'Nome ou PIN incorreto.'
        return
      end

      session[:player_id] = player.id

      # Redireciona baseado na ação escolhida
      if params[:action_type] == 'rejoin' && player.game
        redirect_to game_path(player.game)
      elsif player.game
        # Tem jogo ativo mas escolheu outra ação - redireciona pro jogo mesmo assim
        redirect_to game_path(player.game)
      elsif params[:action_type] == 'create'
        redirect_to new_game_path
      else
        redirect_to join_games_path
      end
    else
      # Criar novo jogador
      if Player.name_exists?(name)
        # Nome já existe - pedir PIN
        redirect_to root_path(name: name, mode: 'login', action_type: params[:action_type]),
          alert: "Este usuário já existe! Informe o PIN para entrar."
        return
      end

      player = Player.new(name: name, pin: pin)

      if player.save
        session[:player_id] = player.id

        if params[:action_type] == 'create'
          redirect_to new_game_path
        else
          redirect_to join_games_path
        end
      else
        redirect_to root_path, alert: player.errors.full_messages.join(', ')
      end
    end
  end

  def update
    name = params[:name].to_s.strip

    if name.blank?
      redirect_back fallback_location: root_path, alert: 'Nome não pode estar vazio.'
      return
    end

    # Verifica se o nome já existe (exceto o próprio jogador)
    if Player.where.not(id: current_player.id).exists?(name: name)
      redirect_back fallback_location: root_path, alert: 'Este nome já está em uso.'
      return
    end

    current_player.update!(name: name)
    redirect_back fallback_location: root_path, notice: 'Nome atualizado com sucesso!'
  end
end
