class CardShare < ApplicationRecord
  belongs_to :game
  belongs_to :from_player, class_name: 'Player'
  belongs_to :to_player, class_name: 'Player'

  validates :share_type, inclusion: { in: %w[card color] }
  validates :status, inclusion: { in: %w[pending accepted rejected] }

  scope :pending, -> { where(status: 'pending') }
  scope :accepted, -> { where(status: 'accepted') }
  scope :for_round, ->(round) { where(round: round) }
  scope :between_players, ->(player1, player2) {
    where(from_player: player1, to_player: player2)
      .or(where(from_player: player2, to_player: player1))
  }

  # Verifica se dois jogadores já compartilharam cartas em qualquer rodada
  def self.players_shared?(player1, player2)
    accepted.between_players(player1, player2).exists?
  end

  # Aceita o card share e processa os efeitos especiais
  def accept!
    return false unless status == 'pending'

    transaction do
      update!(status: 'accepted')
      process_special_effects!
    end

    true
  end

  def reject!
    update!(status: 'rejected')
  end

  private

  def process_special_effects!
    # Efeito da Batata Quente - troca de cartas
    if from_player.role == 'hot_potato' || to_player.role == 'hot_potato'
      handle_hot_potato_swap!
    end

    # Efeito do Zumbi - infecta o outro jogador
    if from_player.role == 'zombie' || from_player.is_infected?
      infect_player!(to_player)
    end
    if to_player.role == 'zombie' || to_player.is_infected?
      infect_player!(from_player)
    end

    # Efeito do Dr. Boom - vitória instantânea se compartilhar com presidente
    if dr_boom_wins?
      game.update!(status: 'finished', winning_team: 'red')
    end
  end

  def handle_hot_potato_swap!
    hot_potato_player = from_player.role == 'hot_potato' ? from_player : to_player
    other_player = from_player.role == 'hot_potato' ? to_player : from_player

    # Salva os roles originais se ainda não foram salvos
    hot_potato_player.update!(original_role: hot_potato_player.role) if hot_potato_player.original_role.nil?
    other_player.update!(original_role: other_player.role) if other_player.original_role.nil?

    # Troca os roles
    temp_role = hot_potato_player.role
    temp_team = hot_potato_player.team

    hot_potato_player.update!(
      role: other_player.role,
      team: other_player.team
    )
    other_player.update!(
      role: temp_role,
      team: temp_team
    )
  end

  def infect_player!(player)
    return if player.role == 'zombie' # Zumbis não podem ser infectados novamente
    return if player.is_infected? # Já está infectado

    player.update!(is_infected: true)
  end

  def dr_boom_wins?
    (from_player.role == 'dr_boom' && to_player.role == 'president') ||
      (to_player.role == 'dr_boom' && from_player.role == 'president')
  end
end

