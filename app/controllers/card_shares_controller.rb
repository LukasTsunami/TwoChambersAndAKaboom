class CardSharesController < ApplicationController
  before_action :require_player!
  before_action :set_game
  before_action :set_card_share, only: [:accept, :reject]

  # GET /games/:game_id/card_shares
  def index
    @pending_requests = CardShare.pending
      .where(game: @game, to_player: current_player)
      .includes(:from_player)

    @my_requests = CardShare.pending
      .where(game: @game, from_player: current_player)
      .includes(:to_player)

    @history = CardShare.accepted
      .where(game: @game)
      .where('from_player_id = ? OR to_player_id = ?', current_player.id, current_player.id)
      .includes(:from_player, :to_player)
      .order(created_at: :desc)
      .limit(10)
  end

  # POST /games/:game_id/card_shares
  def create
    to_player = @game.players.find_by(id: params[:to_player_id])

    unless to_player
      redirect_to @game, alert: 'Jogador não encontrado.'
      return
    end

    if to_player == current_player
      redirect_to @game, alert: 'Você não pode compartilhar carta consigo mesmo.'
      return
    end

    # Verifica se já existe um pedido pendente entre esses jogadores
    existing = CardShare.pending.between_players(current_player, to_player).where(game: @game).first
    if existing
      redirect_to @game, alert: 'Já existe uma solicitação pendente com este jogador.'
      return
    end

    share_type = params[:share_type] || 'card'

    @card_share = CardShare.new(
      game: @game,
      from_player: current_player,
      to_player: to_player,
      share_type: share_type,
      round: @game.current_round,
      status: 'pending'
    )

    if @card_share.save
      broadcast_card_share_request(@card_share)
      redirect_to @game, notice: 'Solicitação de card share enviada!'
    else
      redirect_to @game, alert: 'Erro ao enviar solicitação.'
    end
  end

  # POST /games/:game_id/card_shares/:id/accept
  def accept
    unless @card_share.to_player == current_player
      redirect_to @game, alert: 'Você não pode aceitar esta solicitação.'
      return
    end

    if @card_share.accept!
      broadcast_card_share_accepted(@card_share)

      # Verifica se o jogo acabou (Dr. Boom)
      @game.reload
      if @game.status == 'finished'
        broadcast_game_update
        redirect_to @game, notice: 'Dr. Boom revelou-se para o Presidente! O time vermelho venceu!'
      else
        redirect_to @game, notice: 'Card share aceito!'
      end
    else
      redirect_to @game, alert: 'Erro ao aceitar card share.'
    end
  end

  # POST /games/:game_id/card_shares/:id/reject
  def reject
    unless @card_share.to_player == current_player
      redirect_to @game, alert: 'Você não pode rejeitar esta solicitação.'
      return
    end

    @card_share.reject!
    broadcast_card_share_rejected(@card_share)
    redirect_to @game, notice: 'Card share recusado.'
  end

  private

  def set_game
    @game = Game.find(params[:game_id])
  end

  def set_card_share
    @card_share = CardShare.find(params[:id])
  end

  def broadcast_card_share_request(card_share)
    # Notifica o jogador alvo
    Turbo::StreamsChannel.broadcast_append_to(
      "player_#{card_share.to_player.id}",
      target: "card_share_notifications",
      partial: "card_shares/notification",
      locals: { card_share: card_share }
    )
  end

  def broadcast_card_share_accepted(card_share)
    # Notifica ambos os jogadores
    [card_share.from_player, card_share.to_player].each do |player|
      Turbo::StreamsChannel.broadcast_replace_to(
        "player_#{player.id}",
        target: "game_content",
        partial: "games/game_content",
        locals: { game: @game, player: player }
      )
    end
  end

  def broadcast_card_share_rejected(card_share)
    # Notifica o jogador que fez a solicitação
    Turbo::StreamsChannel.broadcast_append_to(
      "player_#{card_share.from_player.id}",
      target: "flash_messages",
      partial: "shared/flash",
      locals: { type: 'alert', message: "#{card_share.to_player.name} recusou seu card share." }
    )
  end

  def broadcast_game_update
    @game.reload
    @game.players.reload.each do |player|
      Turbo::StreamsChannel.broadcast_replace_to(
        "player_#{player.id}",
        target: "game_content",
        partial: "games/game_content",
        locals: { game: @game, player: player }
      )
    end
  end
end

