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

    # Broadcast para todos os jogadores
    Turbo::StreamsChannel.broadcast_replace_to(
      "game_#{@game.id}",
      target: "game_content",
      partial: "games/game_content",
      locals: { game: @game, player: nil }
    )

    redirect_to @game
  end

  def select_leader
    player_id = params[:leader_id]
    leader = @game.players.find_by(id: player_id, room: current_player.room)

    if leader
      # Remove líder anterior da mesma sala
      @game.players.where(room: current_player.room).update_all(is_leader: false)
      leader.update!(is_leader: true)

      # Verifica se ambas as salas têm líderes
      if @game.room_1_leader && @game.room_2_leader
        @game.start_hostage_exchange!
      end

      broadcast_game_update
    end

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

    # Marca os selecionados como hostages (temporariamente)
    @game.players.where(room: current_player.room, is_hostage: true).update_all(is_hostage: false)
    @game.players.where(id: hostage_ids, room: current_player.room).update_all(is_hostage: true)

    broadcast_game_update
    redirect_to @game
  end

  def exchange
    # Verifica se ambos os líderes selecionaram os reféns
    room1_hostages = @game.room_1_players.where(is_hostage: true)
    room2_hostages = @game.room_2_players.where(is_hostage: true)
    required = @game.hostages_for_current_round

    if room1_hostages.count == required && room2_hostages.count == required
      # Troca os reféns de sala
      room1_hostage_ids = room1_hostages.pluck(:id)
      room2_hostage_ids = room2_hostages.pluck(:id)

      @game.exchange_hostages!(room1_hostage_ids, room2_hostage_ids)
      broadcast_game_update
    else
      redirect_to @game, alert: 'Ambos os líderes precisam selecionar os reféns primeiro.'
      return
    end

    redirect_to @game
  end

  def leave
    if current_player.game
      game = current_player.game
      was_creator = current_player.is_creator

      current_player.leave_game!

      # Se era o criador e o jogo está esperando, transfere ou deleta
      if was_creator && game.status == 'waiting'
        new_creator = game.players.first
        if new_creator
          new_creator.update!(is_creator: true)
        else
          game.destroy
        end
      end

      broadcast_game_update(game) if game.persisted?
    end

    redirect_to root_path
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
    # Broadcast individual para cada jogador
    game.players.each do |player|
      Turbo::StreamsChannel.broadcast_replace_to(
        "player_#{player.id}",
        target: "game_content",
        partial: "games/game_content",
        locals: { game: game, player: player }
      )
    end
  end
end

