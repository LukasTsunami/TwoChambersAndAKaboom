class Game < ApplicationRecord
  has_many :players, dependent: :destroy

  validates :code, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[waiting playing leader_selection hostage_exchange finished] }
  validates :round_time, numericality: { greater_than: 0 }
  validates :total_rounds, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }

  before_validation :generate_code, on: :create

  scope :active, -> { where.not(status: 'finished') }

  # Regras oficiais de rodadas baseadas no número de jogadores
  ROUNDS_BY_PLAYERS = {
    6 => 1,
    7 => 1,
    8 => 2,
    9 => 2,
    10 => 2,
    11 => 3,
    12 => 3,
    13 => 3,
    14 => 3,
    15 => 3,
    16 => 3,
    17 => 3,
    18 => 3,
    19 => 3,
    20 => 3
  }.freeze

  # Regras oficiais de reféns por rodada baseadas no número de jogadores
  # [rodada1, rodada2, rodada3]
  HOSTAGES_BY_PLAYERS = {
    6 => [1, 1, 1],
    7 => [2, 1, 1],
    8 => [2, 1, 1],
    9 => [2, 2, 1],
    10 => [2, 2, 1],
    11 => [3, 2, 1],
    12 => [3, 2, 1],
    13 => [3, 2, 1],
    14 => [3, 2, 1],
    15 => [4, 3, 2],
    16 => [4, 3, 2],
    17 => [5, 4, 3],
    18 => [5, 4, 3],
    19 => [5, 4, 3],
    20 => [5, 4, 3]
  }.freeze

  def creator
    players.find_by(is_creator: true)
  end

  def can_start?
    status == 'waiting' && players.count >= 4
  end

  def hostages_for_current_round
    count = players.count.clamp(6, 20)
    hostages = HOSTAGES_BY_PLAYERS[count] || [1, 1, 1]
    hostages[current_round - 1] || 1
  end

  def recommended_rounds
    count = players.count.clamp(6, 20)
    ROUNDS_BY_PLAYERS[count] || 3
  end

  def room_1_players
    players.where(room: 1)
  end

  def room_2_players
    players.where(room: 2)
  end

  def room_1_leader
    players.find_by(room: 1, is_leader: true)
  end

  def room_2_leader
    players.find_by(room: 2, is_leader: true)
  end

  def start_game!
    return unless can_start?

    # Se total_rounds for 0, usa o recomendado baseado no número de jogadores
    actual_rounds = total_rounds == 0 ? recommended_rounds : total_rounds

    assign_teams_and_roles!
    assign_rooms!

    update!(
      status: 'playing',
      current_round: 1,
      total_rounds: actual_rounds,
      round_started_at: Time.current,
      round_ends_at: Time.current + round_time.seconds
    )
  end

  def start_next_round!
    players.update_all(is_leader: false, is_hostage: false)

    if current_round >= total_rounds
      finish_game!
    else
      update!(
        status: 'playing',
        current_round: current_round + 1,
        round_started_at: Time.current,
        round_ends_at: Time.current + round_time.seconds
      )
    end
  end

  def start_leader_selection!
    update!(status: 'leader_selection')
  end

  def start_hostage_exchange!
    update!(status: 'hostage_exchange')
  end

  def exchange_hostages!(room1_hostage_ids, room2_hostage_ids)
    # Marca os hostages
    players.where(id: room1_hostage_ids).update_all(is_hostage: true, room: 2)
    players.where(id: room2_hostage_ids).update_all(is_hostage: true, room: 1)

    start_next_round!
  end

  def finish_game!
    president = players.find_by(role: 'president')
    bomber = players.find_by(role: 'bomber')

    winning = if president&.room == bomber&.room
                'red' # Bomba explodiu o presidente
              else
                'blue' # Presidente sobreviveu
              end

    update!(status: 'finished', winning_team: winning)
  end

  def time_remaining
    return 0 unless round_ends_at

    remaining = (round_ends_at - Time.current).to_i
    [remaining, 0].max
  end

  def round_expired?
    round_ends_at.present? && Time.current >= round_ends_at
  end

  private

  def generate_code
    self.code ||= loop do
      random_code = SecureRandom.alphanumeric(6).upcase
      break random_code unless Game.exists?(code: random_code)
    end
  end

  def assign_teams_and_roles!
    shuffled = players.to_a.shuffle

    half = shuffled.size / 2
    blue_team = shuffled[0...half]
    red_team = shuffled[half..]

    # Time azul - tem o presidente
    blue_team.each_with_index do |player, index|
      player.update!(team: 'blue', role: index == 0 ? 'president' : 'regular')
    end

    # Time vermelho - tem a bomba
    red_team.each_with_index do |player, index|
      player.update!(team: 'red', role: index == 0 ? 'bomber' : 'regular')
    end
  end

  def assign_rooms!
    all_players = players.reload.to_a.shuffle
    half = all_players.size / 2

    all_players[0...half].each { |p| p.update!(room: 1) }
    all_players[half..].each { |p| p.update!(room: 2) }
  end
end

