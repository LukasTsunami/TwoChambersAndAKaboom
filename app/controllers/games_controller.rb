class GamesController < ApplicationController
  before_action :require_player!
  before_action :set_game, only: [:show, :start, :select_leader, :select_hostages, :exchange]

  def new
    @game = Game.new
  end

  def create
    @game = Game.new(game_params)

    if @game.save
      current_player.update!(game: @game, is_creator: true)
      redirect_to @game
    else
      render :new, status: :unprocessable_entity
    end
  end

  def join
    # Página para digitar o código
  end

  def enter
    code = params[:code].to_s.strip.upcase
    @game = Game.find_by(code: code)

    if @game.nil?
      redirect_to join_games_path, alert: 'Sala não encontrada.'
    elsif @game.status != 'waiting'
      redirect_to join_games_path, alert: 'Esta partida já começou.'
    else
      current_player.update!(game: @game)
      redirect_to @game
    end
  end

  def show
    @player = current_player
    @game = current_player.game

    unless @game
      redirect_to root_path, alert: 'Você não está em nenhum jogo.'
      return
    end
  end

  def start
    unless current_player.is_creator
      redirect_to @game, alert: 'Apenas o criador pode iniciar o jogo.'
      return
    end

    unless @game.can_start?
      redirect_to @game, alert: 'É necessário pelo menos 4 jogadores para começar.'
      return
    end

    @game.start_game!

    # Broadcast para todos os jogadores (envia player individual para cada um)
    broadcast_game_update

    redirect_to @game
  end

  def select_leader
    player_id = params[:leader_id]
    candidate = @game.players.find_by(id: player_id, room: current_player.room)

    unless candidate
      redirect_to @game, alert: 'Jogador inválido.'
      return
    end

    # Registra o voto do jogador atual
    current_player.update!(leader_vote_id: candidate.id)

    # Tenta finalizar a eleição
    result = @game.try_finalize_leader_election!

    case result
    when :tie_room_1
      @game.reset_votes_for_room!(1)
      flash[:alert] = 'Empate na Sala 1! Votem novamente.'
    when :tie_room_2
      @game.reset_votes_for_room!(2)
      flash[:alert] = 'Empate na Sala 2! Votem novamente.'
    when :success
      flash[:notice] = 'Líderes eleitos!'
    end

    broadcast_game_update
    redirect_to @game
  end

  def select_hostages
    # Apenas líderes podem selecionar reféns
    unless current_player.is_leader
      redirect_to @game, alert: 'Apenas o líder pode selecionar reféns.'
      return
    end

    hostage_ids = params[:hostage_ids] || []

    # Verifica se a quantidade está correta
    required = @game.hostages_for_current_round
    if hostage_ids.size != required
      redirect_to @game, alert: "Selecione exatamente #{required} refém(s)."
      return
    end

    # Marca os selecionados como hostages
    @game.players.where(room: current_player.room, is_hostage: true).update_all(is_hostage: false)
    @game.players.where(id: hostage_ids, room: current_player.room).update_all(is_hostage: true)

    # Verifica se ambos os times já selecionaram - se sim, executa a troca automaticamente
    @game.reload
    room1_hostages = @game.room_1_players.where(is_hostage: true)
    room2_hostages = @game.room_2_players.where(is_hostage: true)

    if room1_hostages.count == required && room2_hostages.count == required
      # Troca os reféns de sala automaticamente
      room1_hostage_ids = room1_hostages.pluck(:id)
      room2_hostage_ids = room2_hostages.pluck(:id)

      @game.exchange_hostages!(room1_hostage_ids, room2_hostage_ids)
    end

    broadcast_game_update
    redirect_to @game
  end

  def exchange
    # Este método não é mais necessário pois a troca acontece automaticamente
    # Mantido apenas para compatibilidade
    redirect_to @game
  end

  # Sair do jogo - apenas volta pra home, continua associado ao jogo
  def exit_game
    session.delete(:player_id)
    redirect_to root_path
  end

  # Abandonar o jogo - desassocia o jogador da sala
  def abandon
    if current_player.game
      game = current_player.game

      # Criador só pode abandonar se o jogo já terminou
      if current_player.is_creator && game.status != 'finished'
        redirect_to game, alert: 'O criador não pode abandonar a sala durante o jogo. Use "Apagar Sala" ou "Sair do Jogo".'
        return
      end

      current_player.leave_game!
      broadcast_game_update(game) if game.persisted?
    end

    session.delete(:player_id)
    redirect_to root_path, notice: "Você saiu da sala."
  end

  # Apagar a sala - destrói o jogo (só para criador)
  def destroy_room
    if current_player.game
      game = current_player.game

      unless current_player.is_creator
        redirect_to game, alert: 'Apenas o criador pode apagar a sala.'
        return
      end

      current_player.leave_game!
      game.destroy
    end

    session.delete(:player_id)
    redirect_to root_path, notice: "Sala apagada com sucesso!"
  end

  def timer_expired
    @game = Game.find(params[:id])

    if @game.status == 'playing' && @game.round_expired?
      @game.start_leader_selection!
      broadcast_game_update
    end

    head :ok
  end

  private

  def set_game
    @game = Game.find(params[:id])
  end

  def game_params
    params.require(:game).permit(:round_time, :total_rounds)
  end

  def broadcast_game_update(game = @game)
    # Recarrega o game e players do banco para pegar dados atualizados
    game.reload

    # Broadcast individual para cada jogador
    game.players.reload.each do |player|
      Turbo::StreamsChannel.broadcast_replace_to(
        "player_#{player.id}",
        target: "game_content",
        partial: "games/game_content",
        locals: { game: game, player: player }
      )
    end
  end
end

