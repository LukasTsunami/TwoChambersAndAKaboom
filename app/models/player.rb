class Player < ApplicationRecord
  include RoleDefinitions

  belongs_to :game, optional: true
  has_many :card_shares_sent, class_name: 'CardShare', foreign_key: 'from_player_id', dependent: :destroy
  has_many :card_shares_received, class_name: 'CardShare', foreign_key: 'to_player_id', dependent: :destroy

  validates :name, presence: true
  validates :session_token, presence: true, uniqueness: true
  validates :pin, presence: true, length: { is: 3 }, format: { with: /\A\d{3}\z/, message: "deve ter exatamente 3 dígitos numéricos" }
  validates :name, uniqueness: { scope: :pin, message: "já existe com este PIN" }

  before_validation :generate_session_token, on: :create

  scope :in_game, -> { where.not(game_id: nil) }

  def self.authenticate(name, pin)
    find_by(name: name.to_s.strip, pin: pin.to_s.strip)
  end

  def self.name_exists?(name)
    exists?(name: name.to_s.strip)
  end

  def reset_pin!
    update!(pin: "000")
  end

  # Informações do role baseadas nas definições
  def role_info
    ROLES[role.to_sym] if role.present?
  end

  def team_name
    case team
    when 'red' then 'Vermelho'
    when 'blue' then 'Azul'
    when 'green' then 'Verde'
    when 'black' then 'Preto'
    end
  end

  def role_name
    info = role_info
    return info[:name] if info

    case role
    when 'president' then 'Presidente'
    when 'bomber' then 'Bomba'
    when 'regular' then 'Membro do Time'
    when 'dr_boom' then 'Dr. Boom'
    when 'engineer' then 'Engenheiro'
    when 'fanatic' then 'Fanático Religioso'
    when 'doctor' then 'Médico'
    when 'agent' then 'Agente'
    when 'soldier' then 'Soldado'
    when 'hot_potato' then 'Batata Quente'
    when 'gambler' then 'Apostador'
    when 'evil_genius' then 'Gênio do Mal'
    when 'stepfather' then 'Padrasto'
    when 'zombie' then 'Zumbi'
    when /citizen/ then 'Cidadão'
    when /spy/ then 'Espião'
    when /mime/ then 'Mímico'
    when /usurper/ then 'Usurpadora'
    when /kangaroo/ then 'Canguru'
    when /gargoyle/ then 'Gárgula'
    when /pirate/ then 'Pirata'
    when /enlisted/ then 'Alistado'
    else 'Membro do Time'
    end
  end

  def role_description
    info = role_info
    return info[:description] if info

    case role
    when 'president'
      'Você é o Presidente! Seu objetivo é sobreviver. Não esteja na mesma sala que a Bomba no final do jogo.'
    when 'bomber'
      'Você é a Bomba! Seu objetivo é estar na mesma sala que o Presidente no final do jogo para explodir!'
    when 'dr_boom'
      'Se você fizer card share com o Presidente, o jogo acaba imediatamente e o time vermelho vence.'
    when 'engineer'
      'Você precisa fazer card share com a Bomba antes do final do jogo, ou a bomba não é armada e o time vermelho perde.'
    when 'fanatic'
      'Você só ganha se estiver na sala onde a bomba explode no final do jogo.'
    when 'doctor'
      'Você precisa fazer card share com o Presidente antes do final do jogo, ou o time azul perde.'
    when 'agent'
      'Uma vez por rodada, você pode revelar sua carta em privado e forçar um jogador a fazer card share com você.'
    when 'soldier'
      'Seu voto conta duas vezes na escolha de líder.'
    when 'hot_potato'
      'Quem fizer card share (ou até color share) troca de carta imediatamente com você.'
    when 'gambler'
      'No final do jogo você tenta adivinhar qual time vai ganhar. Se acertar, você ganha sozinho!'
    when 'evil_genius'
      'Você ganha o jogo se você tiver sido líder de cada uma das salas pelo menos uma vez.'
    when 'stepfather'
      'Revele sua carta para dois jogadores no começo do jogo. Diga "vocês são meus filhos". Você ganha se eles estiverem no mesmo quarto no final.'
    when 'zombie'
      'Você contamina jogadores que compartilharem cartas com você. Vocês ganham se terminarem numa sala só com zumbis e não estiverem sendo explodidos.'
    when /spy/
      enemy_team = team == 'blue' ? 'vermelho' : 'azul'
      "Você conta como membro do time #{enemy_team}, mesmo que sua cor seja #{team_name.downcase}."
    when /mime/
      'Você não pode falar, apenas se comunicar com gestos.'
    when /usurper/
      'Uma vez por jogo, na votação para líder e antes da última rodada, você pode revelar sua carta e se tornar líder da sua sala.'
    when /kangaroo/
      'Uma vez por jogo, na etapa de discussão, você pode revelar sua carta e ir imediatamente para a outra sala.'
    when /gargoyle/
      'Você pode escolher não ser mandado como refém para a outra sala. Outro jogador deve ir no seu lugar.'
    when /pirate/
      'Uma vez por jogo, antes da última rodada, você pode escolher um jogador para ser obrigado a ser mandado como refém.'
    when /enlisted/
      'Uma vez por jogo, antes da última rodada, você pode escolher a si mesmo para ser mandado como refém.'
    when /citizen/
      team == 'blue' ? 'Ajude a proteger o Presidente! Mantenha-o longe da Bomba.' : 'Ajude a Bomba a encontrar o Presidente!'
    when 'regular'
      team == 'blue' ? 'Ajude a proteger o Presidente! Mantenha-o longe da Bomba.' : 'Ajude a Bomba a encontrar o Presidente!'
    else
      'Participe do jogo e ajude seu time a vencer!'
    end
  end

  def team_mission
    case team
    when 'blue'
      '🔵 TIME AZUL: Proteja o Presidente! Garanta que ele NÃO esteja na mesma sala que a Bomba no final do jogo.'
    when 'red'
      '🔴 TIME VERMELHO: Encontre o Presidente! A Bomba deve estar na mesma sala que o Presidente no final do jogo.'
    when 'green'
      '🟢 TIME VERDE: Infecte outros jogadores através de card share! Ganhe se sua sala tiver apenas zumbis e não for explodida.'
    when 'black'
      case role
      when 'gambler'
        '⚫ APOSTADOR: Adivinhe qual time vai vencer. Se acertar, você ganha sozinho!'
      when 'evil_genius'
        '⚫ GÊNIO DO MAL: Torne-se líder de ambas as salas pelo menos uma vez para vencer!'
      when 'stepfather'
        '⚫ PADRASTO: Seus "filhos" devem estar na mesma sala no final do jogo para você vencer!'
      when 'hot_potato'
        '⚫ BATATA QUENTE: Passe sua carta para outro jogador através de card share!'
      else
        '⚫ TIME PRETO: Complete seu objetivo especial para vencer!'
      end
    end
  end

  def role_icon
    info = role_info
    return info[:icon] if info

    case role
    when 'president' then '👔'
    when 'bomber' then '💣'
    when 'dr_boom' then '🧨'
    when 'engineer' then '🔧'
    when 'fanatic' then '⛪'
    when 'doctor' then '⚕️'
    when 'agent' then '🕵️'
    when 'soldier' then '🎖️'
    when 'hot_potato' then '🥔'
    when 'gambler' then '🎰'
    when 'evil_genius' then '🧠'
    when 'stepfather' then '👨‍👧‍👦'
    when 'zombie' then '🧟'
    when /spy/ then team == 'blue' ? '🔴' : '🔵'
    when /mime/ then '🤐'
    when /usurper/ then '👑'
    when /kangaroo/ then '🦘'
    when /gargoyle/ then '🗿'
    when /pirate/ then '🏴‍☠️'
    when /enlisted/ then '🙋'
    when /citizen/ then team == 'blue' ? '🔵' : '🔴'
    else team == 'blue' ? '🔵' : '🔴'
    end
  end

  def team_color
    case team
    when 'blue' then 'blue'
    when 'red' then 'red'
    when 'green' then 'green'
    when 'black' then 'slate'
    else 'slate'
    end
  end

  def card_background_class
    case team
    when 'blue'
      'bg-gradient-to-br from-blue-900 to-blue-950 border-blue-500 glow-blue'
    when 'red'
      'bg-gradient-to-br from-red-900 to-red-950 border-red-500 glow-red'
    when 'green'
      'bg-gradient-to-br from-green-900 to-green-950 border-green-500 glow-green'
    when 'black'
      'bg-gradient-to-br from-slate-800 to-slate-950 border-slate-400 glow-slate'
    else
      'bg-gradient-to-br from-slate-700 to-slate-800 border-slate-600'
    end
  end

  def team_badge_class
    case team
    when 'blue'
      'bg-blue-500/30 text-blue-300'
    when 'red'
      'bg-red-500/30 text-red-300'
    when 'green'
      'bg-green-500/30 text-green-300'
    when 'black'
      'bg-slate-500/30 text-slate-300'
    else
      'bg-slate-500/30 text-slate-300'
    end
  end

  def has_special_ability?
    %w[agent usurper_blue usurper_red kangaroo_blue kangaroo_red 
       gargoyle_blue gargoyle_red pirate_blue pirate_red 
       enlisted_blue enlisted_red stepfather].include?(role)
  end

  def ability_partial
    case role
    when 'agent' then 'agent'
    when /usurper/ then 'usurper'
    when /kangaroo/ then 'kangaroo'
    when /gargoyle/ then 'gargoyle'
    when /pirate/ then 'pirate'
    when /enlisted/ then 'enlisted'
    when 'stepfather' then 'stepfather'
    else nil
    end
  end

  # Verifica se o jogador pode usar sua habilidade neste momento
  def can_use_ability?(game)
    return false if ability_used?
    return false unless has_special_ability?

    case role
    when /usurper/
      game.status == 'leader_selection' && game.current_round < game.total_rounds
    when /kangaroo/
      game.status == 'playing'
    when /gargoyle/
      game.status == 'hostage_exchange'
    when /pirate/, /enlisted/
      game.status == 'hostage_exchange' && game.current_round < game.total_rounds
    when 'agent'
      game.status == 'playing'
    when 'stepfather'
      game.current_round == 1 && stepfather_children.blank?
    else
      false
    end
  end

  def leave_game!
    update!(
      game: nil,
      team: nil,
      role: nil,
      room: nil,
      is_creator: false,
      is_leader: false,
      is_hostage: false,
      leader_vote_id: nil,
      ability_used: false,
      is_infected: false,
      stepfather_children: nil,
      gambler_guess: nil,
      times_was_leader_room1: 0,
      times_was_leader_room2: 0,
      original_role: nil
    )
  end

  private

  def generate_session_token
    self.session_token ||= SecureRandom.uuid
  end
end
