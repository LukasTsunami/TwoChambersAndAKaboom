class GamesController < ApplicationController
  before_action :require_player!
  before_action :set_game, only: [:show, :start, :select_leader, :usurp_leadership, :select_hostages, :gargoyle_decision, :exchange, :ability]

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

    current_player.update!(leader_vote_id: candidate.id)
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

  def usurp_leadership
    @game = Game.find(params[:id])

    unless current_player.role&.include?('usurper')
      redirect_to @game, alert: "Apenas a Usurpadora pode fazer isso."
      return
    end

    if current_player.is_leader
      redirect_to @game, alert: "Você já é o líder!"
      return
    end

    ActiveRecord::Base.transaction do
      # 1. Destitui líder anterior
      old_leader = @game.players.find_by(room: current_player.room, is_leader: true)
      old_leader_name = old_leader ? old_leader.name : "Ninguém"
      
      if old_leader
        old_leader.update!(is_leader: false)
        # Limpa reféns selecionados pelo antigo líder
        @game.players.where(room: current_player.room).update_all(is_hostage: false)
      end
      
      # 2. Promove Usurpadora
      current_player.update!(is_leader: true)
      
      # 3. SALVA A MENSAGEM NO BANCO (Para todos verem)
      message = "👑 GOLPE DE ESTADO! #{current_player.name} roubou a liderança de #{old_leader_name}!"
      @game.update!(usurp_message: message)
      
      # Opcional: current_player.update!(ability_used: true)
    end

    # Força reload e avisa a todos
    @game.reload
    broadcast_game_update
    
    redirect_to @game
  end
    
  def select_hostages
    unless current_player.is_leader
      redirect_to @game, alert: 'Apenas o líder pode selecionar reféns.'
      return
    end
  
    hostage_ids = params[:hostage_ids] || [].reject(&:blank?)
    
    my_room_players = @game.players.where(room: current_player.room)
    is_leader_alone = my_room_players.count <= 1
    required = !is_leader_alone ? @game.hostages_for_current_round : 0
  
    if hostage_ids.size != required && !is_leader_alone
      redirect_to @game, alert: "Selecione exatamente #{required} refém(s)."
      return
    end
  
    my_room_players.update_all(is_hostage: false)
  
    if hostage_ids.any? && !is_leader_alone
      @game.players.where(id: hostage_ids).update_all(is_hostage: true)
    end
  
    # Verifica gárgulas que podem recusar (ability_used = false)
    gargoyles_needing_decision = @game.players.where(id: hostage_ids)
      .select { |p| p.role&.include?('gargoyle') && !p.ability_used? }
    
    if gargoyles_needing_decision.any?
      pending = @game.parsed_gargoyle_pending || {}
      gargoyles_needing_decision.each do |g|
        pending[g.id.to_s] = nil  # nil = ainda não decidiu
      end
      @game.update!(gargoyle_pending_decisions: pending.to_json)
      
      flash[:notice] = "Aguardando decisão do(s) Gárgula(s)..."
    else
      # Gárgulas que já usaram habilidade vão automaticamente
      flash[:notice] = "Reféns confirmados. Aguardando a outra sala..."
    end
  
    try_execute_exchange!
    
    broadcast_game_update
    redirect_to @game
  end

  def gargoyle_decision
    unless current_player.role&.include?('gargoyle')
      redirect_to @game, alert: 'Apenas gárgulas podem usar isso.'
      return
    end
  
    unless current_player.is_hostage?
      redirect_to @game, alert: 'Você não foi selecionado como refém.'
      return
    end
  
    decision = params[:decision] # 'accept' ou 'refuse'
    
    pending = @game.parsed_gargoyle_pending || {}
    
    if decision == 'refuse'
      if current_player.ability_used?
        redirect_to @game, alert: 'Você já usou sua habilidade de recusa!'
        return
      end
      
      pending[current_player.id.to_s] = 'refused'
      current_player.update!(ability_used: true)
      flash[:notice] = '🗿 Você recusou ir como refém! Ficará na sala.'
    else
      pending[current_player.id.to_s] = 'accepted'
      flash[:notice] = 'Você aceitou ir como refém.'
    end
    
    @game.update!(gargoyle_pending_decisions: pending.to_json)
    
    try_execute_exchange!
    
    broadcast_game_update
    redirect_to @game
  end

  def exchange
    redirect_to @game
  end

  def exit_game
    session.delete(:player_id)
    redirect_to root_path
  end

  def abandon
    if current_player.game
      game = current_player.game

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

  def ability
    ability_name = params[:ability]

    case ability_name
    when 'usurp'
      handle_usurp_ability
    when 'jump'
      handle_kangaroo_ability
    when 'volunteer'
      handle_enlisted_ability
    when 'plank'
      handle_pirate_ability
    when 'force_share'
      handle_agent_ability
    when 'adopt'
      handle_stepfather_ability
    when 'gambler_guess'
      handle_gambler_guess
    else
      redirect_to @game, alert: 'Habilidade desconhecida.'
    end
  end

  private

  def try_execute_exchange!
    @game.reload
    
    # Verifica se ainda há gárgulas pendentes de decisão
    pending = @game.parsed_gargoyle_pending || {}
    if pending.values.any?(&:nil?)
      return # Ainda há gárgulas que não decidiram
    end
    
    # Verifica se ambas as salas confirmaram seus reféns
    r1_total = @game.room_1_players.count
    r1_req = r1_total > 1 ? @game.hostages_for_current_round : 0
    r1_ready = @game.room_1_players.where(is_hostage: true).count == r1_req

    r2_total = @game.room_2_players.count
    r2_req = r2_total > 1 ? @game.hostages_for_current_round : 0
    r2_ready = @game.room_2_players.where(is_hostage: true).count == r2_req

    return unless r1_ready && r2_ready

    hostages_1 = @game.room_1_players.where(is_hostage: true)
    hostages_2 = @game.room_2_players.where(is_hostage: true)

    # Filtra gárgulas que recusaram
    ids_to_move_1 = hostages_1.reject do |p|
      if p.role&.include?('gargoyle')
        pending[p.id.to_s] == 'refused'
      else
        false
      end
    end.map(&:id)

    ids_to_move_2 = hostages_2.reject do |p|
      if p.role&.include?('gargoyle')
        pending[p.id.to_s] == 'refused'
      else
        false
      end
    end.map(&:id)
    
    # Limpa as decisões pendentes
    @game.update!(gargoyle_pending_decisions: nil)
    
    @game.exchange_hostages!(ids_to_move_1, ids_to_move_2)
  end

  def handle_usurp_ability
    unless current_player.role&.include?('usurper')
      redirect_to @game, alert: 'Você não tem essa habilidade.'
      return
    end

    unless current_player.can_use_ability?(@game)
      redirect_to @game, alert: 'Você não pode usar essa habilidade agora.'
      return
    end

    # Remove o líder atual da sala e coloca o usurpador
    current_leader = @game.players.find_by(room: current_player.room, is_leader: true)
    current_leader&.update!(is_leader: false)

    current_player.update!(is_leader: true, ability_used: true)
    broadcast_game_update
    redirect_to @game, notice: 'Você usurpou a liderança!'
  end

  def handle_kangaroo_ability
    unless current_player.role&.include?('kangaroo')
      redirect_to @game, alert: 'Você não tem essa habilidade.'
      return
    end

    unless current_player.can_use_ability?(@game)
      redirect_to @game, alert: 'Você não pode usar essa habilidade agora.'
      return
    end

    new_room = current_player.room == 1 ? 2 : 1
    current_player.update!(room: new_room, ability_used: true)
    broadcast_game_update
    redirect_to @game, notice: "Você pulou para a Sala #{new_room}!"
  end

  def handle_enlisted_ability
    unless current_player.role&.include?('enlisted')
      redirect_to @game, alert: 'Você não tem essa habilidade.'
      return
    end

    unless current_player.can_use_ability?(@game)
      redirect_to @game, alert: 'Você não pode usar essa habilidade agora.'
      return
    end

    current_player.update!(is_hostage: true, ability_used: true)
    broadcast_game_update
    redirect_to @game, notice: 'Você se voluntariou como refém!'
  end

  def handle_pirate_ability
    unless current_player.role&.include?('pirate')
      redirect_to @game, alert: 'Você não tem essa habilidade.'
      return
    end

    unless current_player.can_use_ability?(@game)
      redirect_to @game, alert: 'Você não pode usar essa habilidade agora.'
      return
    end

    target = @game.players.find_by(id: params[:target_player_id], room: current_player.room)
    unless target
      redirect_to @game, alert: 'Jogador inválido.'
      return
    end

    target.update!(room: current_player.room == 1 ? 2 : 1)
    current_player.update!(ability_used: true)
    broadcast_game_update
    redirect_to @game, notice: "#{target.name} foi enviado para a prancha! (Vá para a outra sala imediatamente)"
  end

  def handle_agent_ability
    unless current_player.role == 'agent'
      redirect_to @game, alert: 'Você não tem essa habilidade.'
      return
    end

    unless current_player.can_use_ability?(@game)
      redirect_to @game, alert: 'Você não pode usar essa habilidade agora.'
      return
    end

    target = @game.players.find_by(id: params[:target_player_id], room: current_player.room)
    unless target
      redirect_to @game, alert: 'Jogador inválido.'
      return
    end

    # Cria um card share forçado (já aceito)
    CardShare.create!(
      game: @game,
      from_player: current_player,
      to_player: target,
      share_type: 'card',
      round: @game.current_round,
      status: 'accepted'
    )

    current_player.update!(ability_used: true)
    broadcast_game_update
    redirect_to @game, notice: "Você forçou um card share com #{target.name}!"
  end

  def handle_stepfather_ability
    unless current_player.role == 'stepfather'
      redirect_to @game, alert: 'Você não tem essa habilidade.'
      return
    end

    child1 = @game.players.find_by(id: params[:child1_id])
    child2 = @game.players.find_by(id: params[:child2_id])

    unless child1 && child2 && child1.id != child2.id
      redirect_to @game, alert: 'Selecione dois jogadores diferentes.'
      return
    end

    current_player.update!(
      stepfather_children: [child1.id, child2.id].to_json,
      ability_used: true
    )

    broadcast_game_update
    redirect_to @game, notice: "#{child1.name} e #{child2.name} agora são seus filhos!"
  end

  def handle_gambler_guess
    unless current_player.role == 'gambler'
      redirect_to @game, alert: 'Você não é o Apostador.'
      return
    end

    guess = params[:guess]
    unless %w[blue red].include?(guess)
      redirect_to @game, alert: 'Palpite inválido.'
      return
    end

    current_player.update!(gambler_guess: guess)
    redirect_to @game, notice: "Você apostou no time #{guess == 'blue' ? 'Azul' : 'Vermelho'}!"
  end

  def set_game
    @game = Game.find(params[:id])
  end

  def game_params
    params.require(:game).permit(:round_time, :total_rounds, :role_selection_mode, selected_roles: [])
  end

  def broadcast_game_update(game = @game)
    game.reload
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
