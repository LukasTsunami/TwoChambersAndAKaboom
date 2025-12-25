class Game < ApplicationRecord
  include RoleDefinitions

  has_many :players, dependent: :destroy
  has_many :card_shares, dependent: :destroy

  validates :code, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[waiting playing leader_selection hostage_exchange finished] }
  validates :round_time, numericality: { greater_than: 0 }
  validates :total_rounds, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }
  validates :role_selection_mode, inclusion: { in: %w[manual all by_players random] }, allow_nil: true

  before_validation :generate_code, on: :create
  before_save :serialize_selected_roles

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

  # Roles de jogador ímpar disponíveis
  ODD_PLAYER_ROLES = %w[hot_potato gambler evil_genius stepfather zombie].freeze

  # Roles especiais por time
  SPECIAL_BLUE_ROLES = %w[doctor agent soldier].freeze
  SPECIAL_RED_ROLES = %w[dr_boom engineer fanatic].freeze
  GENERIC_ROLES = %w[spy mime usurper kangaroo gargoyle pirate enlisted].freeze

  def creator
    players.find_by(is_creator: true)
  end

  def can_start?
    status == 'waiting' && players.count >= 2
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

  def parsed_gargoyle_pending
    return {} if gargoyle_pending_decisions.blank?
    JSON.parse(gargoyle_pending_decisions) rescue {}
  end

  def parsed_selected_roles
    return [] if selected_roles.blank?
    JSON.parse(selected_roles) rescue []
  end

  def selected_roles=(value)
    if value.is_a?(Array)
      super(value.reject(&:blank?).to_json)
    else
      super(value)
    end
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
    # Atualiza contadores de liderança para o Gênio do Mal
    update_leader_counts!

    players.update_all(is_leader: false, is_hostage: false, leader_vote_id: nil)

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
    # Limpa votos anteriores
    players.update_all(leader_vote_id: nil, is_leader: false)
    update!(status: 'leader_selection')
  end

  # Contagem de votos para líder em uma sala (considera Soldado com voto duplo)
  def vote_counts_for_room(room_number)
    room_players = players.where(room: room_number)
    votes = {}

    room_players.where.not(leader_vote_id: nil).each do |player|
      vote_weight = player.role == 'soldier' ? 2 : 1
      votes[player.leader_vote_id] ||= 0
      votes[player.leader_vote_id] += vote_weight
    end

    votes
  end

  # Verifica se todos da sala votaram
  def all_voted_in_room?(room_number)
    room_players = players.where(room: room_number)
    room_players.where(leader_vote_id: nil).count == 0
  end

  # Verifica se há empate na sala
  def has_tie_in_room?(room_number)
    counts = vote_counts_for_room(room_number)
    return false if counts.empty?

    max_votes = counts.values.max
    counts.values.count(max_votes) > 1
  end

  # Retorna o líder eleito da sala (ou nil se empate/não decidido)
  def elected_leader_for_room(room_number)
    return nil unless all_voted_in_room?(room_number)
    return nil if has_tie_in_room?(room_number)

    counts = vote_counts_for_room(room_number)
    return nil if counts.empty?

    winner_id = counts.max_by { |_, v| v }&.first
    players.find_by(id: winner_id)
  end

  # Tenta finalizar a votação de líder
  def try_finalize_leader_election!
    result = :waiting

    # Processa sala 1 se todos votaram
    if all_voted_in_room?(1)
      if has_tie_in_room?(1)
        result = :tie_room_1
      elsif room_1_leader.nil?
        # Elege o líder da sala 1 imediatamente
        leader1 = elected_leader_for_room(1)
        leader1&.update!(is_leader: true)
      end
    end

    # Processa sala 2 se todos votaram
    if all_voted_in_room?(2)
      if has_tie_in_room?(2)
        result = :tie_room_2 if result == :waiting
      elsif room_2_leader.nil?
        # Elege o líder da sala 2 imediatamente
        leader2 = elected_leader_for_room(2)
        leader2&.update!(is_leader: true)
      end
    end

    # Verifica se ambos os líderes foram eleitos para passar para próxima fase
    reload
    if room_1_leader.present? && room_2_leader.present?
      start_hostage_exchange!
      return :success
    end

    result
  end

  # Limpa votos de uma sala (para revotação)
  def reset_votes_for_room!(room_number)
    players.where(room: room_number).update_all(leader_vote_id: nil)
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

    # Verifica condições especiais antes de determinar o vencedor
    winning_team = determine_winner(president, bomber)
    individual_winners = determine_individual_winners(president, bomber, winning_team)

    update!(
      status: 'finished',
      winning_team: winning_team
    )

    # Marca vencedores individuais (para roles como Apostador, Gênio do Mal, etc.)
    individual_winners.each do |player|
      player.update!(is_winner: true) if player.respond_to?(:is_winner=)
    end
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

  def serialize_selected_roles
    if selected_roles.is_a?(Array)
      self.selected_roles = selected_roles.reject(&:blank?).to_json
    end
  end

  def update_leader_counts!
    # Atualiza contadores de liderança para o Gênio do Mal
    room_1_leader&.increment!(:times_was_leader_room1)
    room_2_leader&.increment!(:times_was_leader_room2)
  end

  def assign_teams_and_roles!
    shuffled = players.to_a.shuffle
    player_count = shuffled.size
    is_odd = player_count.odd?

    # Se número ímpar, um jogador vai para time preto/verde
    odd_player = nil
    if is_odd
      odd_player = shuffled.pop
      assign_odd_player_role!(odd_player)
    end

    # Divide o resto entre azul e vermelho
    half = shuffled.size / 2
    blue_team = shuffled[0...half]
    red_team = shuffled[half..]

    # Determina os roles disponíveis baseado no modo de seleção
    available_roles = determine_available_roles

    # Atribui roles ao time azul
    assign_team_roles!(blue_team, 'blue', available_roles)

    # Atribui roles ao time vermelho
    assign_team_roles!(red_team, 'red', available_roles)
  end

  def assign_odd_player_role!(player)
    available_odd_roles = determine_odd_player_roles
    selected_role = available_odd_roles.sample || 'gambler'

    # Zumbi é do time verde, os outros são do time preto
    team = selected_role == 'zombie' ? 'green' : 'black'

    player.update!(team: team, role: selected_role)
  end

  def determine_odd_player_roles
    case role_selection_mode
    when 'manual'
      selected = parsed_selected_roles & ODD_PLAYER_ROLES
      selected.empty? ? ['gambler'] : selected
    when 'all'
      ODD_PLAYER_ROLES
    when 'by_players', 'random'
      ODD_PLAYER_ROLES.sample(rand(1..3))
    else
      ['gambler']
    end
  end

  def determine_available_roles
    case role_selection_mode
    when 'manual'
      parsed_selected_roles
    when 'all'
      SPECIAL_BLUE_ROLES + SPECIAL_RED_ROLES + GENERIC_ROLES
    when 'by_players'
      # Mais jogadores = mais roles especiais
      count = players.count
      special_count = (count / 4).clamp(1, 6)
      (SPECIAL_BLUE_ROLES + SPECIAL_RED_ROLES).sample(special_count) +
        GENERIC_ROLES.sample(special_count)
    when 'random'
      all_roles = SPECIAL_BLUE_ROLES + SPECIAL_RED_ROLES + GENERIC_ROLES
      all_roles.sample(rand(2..6))
    else
      []
    end
  end

  def assign_team_roles!(team_players, team_color, available_roles)
    return if team_players.empty?

    # O primeiro jogador recebe o role principal (presidente ou bomba)
    main_role = team_color == 'blue' ? 'president' : 'bomber'
    team_players.first.update!(team: team_color, role: main_role)

    # Filtra roles disponíveis para este time
    team_specific_roles = if team_color == 'blue'
      available_roles & (SPECIAL_BLUE_ROLES + GENERIC_ROLES.map { |r| "#{r}_blue" } + GENERIC_ROLES)
    else
      available_roles & (SPECIAL_RED_ROLES + GENERIC_ROLES.map { |r| "#{r}_red" } + GENERIC_ROLES)
    end

    # Normaliza roles genéricos para incluir o sufixo do time
    normalized_roles = team_specific_roles.map do |role|
      if GENERIC_ROLES.include?(role)
        "#{role}_#{team_color}"
      elsif role.end_with?('_blue') || role.end_with?('_red')
        role
      else
        role
      end
    end

    # Remove roles que não pertencem a este time
    normalized_roles = normalized_roles.select do |role|
      role_info = ROLES[role.to_sym]
      role_info.nil? || role_info[:team] == team_color || GENERIC_ROLES.any? { |g| role.start_with?(g) }
    end

    # Atribui roles aos demais jogadores
    remaining_players = team_players[1..]
    roles_to_assign = normalized_roles.dup.shuffle

    remaining_players.each do |player|
      role = roles_to_assign.shift || "citizen_#{team_color}"
      player.update!(team: team_color, role: role)
    end
  end

  def determine_winner(president, bomber)
    # Verifica condição do Engenheiro (precisa ter feito card share com Bomber)
    engineer = players.find_by(role: 'engineer')
    if engineer.present?
      engineer_shared_with_bomber = card_shares.accepted
        .between_players(engineer, bomber)
        .exists?
      unless engineer_shared_with_bomber
        return 'blue' # Bomba não armada, azul vence
      end
    end

    # Verifica condição do Médico (precisa ter feito card share com Presidente)
    doctor = players.find_by(role: 'doctor')
    if doctor.present?
      doctor_shared_with_president = card_shares.accepted
        .between_players(doctor, president)
        .exists?
      unless doctor_shared_with_president
        return 'red' # Presidente não protegido, vermelho vence
      end
    end

    # Condição padrão: Bomba e Presidente na mesma sala?
    if president&.room == bomber&.room
      'red' # Bomba explodiu o presidente
    else
      'blue' # Presidente sobreviveu
    end
  end

  def determine_individual_winners(president, bomber, team_winner)
    winners = []

    # Apostador - acertou o time vencedor?
    gambler = players.find_by(role: 'gambler')
    if gambler.present? && gambler.gambler_guess == team_winner
      winners << gambler
    end

    # Gênio do Mal - foi líder em ambas as salas?
    evil_genius = players.find_by(role: 'evil_genius')
    if evil_genius.present? &&
       evil_genius.times_was_leader_room1.to_i > 0 &&
       evil_genius.times_was_leader_room2.to_i > 0
      winners << evil_genius
    end

    # Padrasto - filhos estão na mesma sala?
    stepfather = players.find_by(role: 'stepfather')
    if stepfather.present? && stepfather.stepfather_children.present?
      children_ids = JSON.parse(stepfather.stepfather_children) rescue []
      children = players.where(id: children_ids)
      if children.count == 2 && children.first.room == children.last.room
        winners << stepfather
      end
    end

    # Fanático - está na sala onde a bomba explodiu?
    fanatic = players.find_by(role: 'fanatic')
    if fanatic.present? && team_winner == 'red' && fanatic.room == president&.room
      winners << fanatic
    end

    # Zumbis - sala só com zumbis e sem bomba?
    zombies = players.where(role: 'zombie').or(players.where(is_infected: true))
    if zombies.any?
      [1, 2].each do |room|
        room_players = players.where(room: room)
        all_zombies = room_players.all? { |p| p.role == 'zombie' || p.is_infected? }
        no_bomber = !room_players.exists?(role: 'bomber')
        if all_zombies && no_bomber && room_players.count > 0
          winners.concat(room_players.to_a)
        end
      end
    end

    winners.uniq
  end

  def assign_rooms!
    all_players = players.reload.to_a.shuffle
    half = all_players.size / 2

    all_players[0...half].each { |p| p.update!(room: 1) }
    all_players[half..].each { |p| p.update!(room: 2) }
  end
end
