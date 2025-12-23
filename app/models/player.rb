class Player < ApplicationRecord
  belongs_to :game, optional: true

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

  def team_name
    case team
    when 'red' then 'Vermelho'
    when 'blue' then 'Azul'
    end
  end

  def role_name
    case role
    when 'president' then 'Presidente'
    when 'bomber' then 'Bomba'
    when 'regular' then 'Membro do Time'
    end
  end

  def role_description
    case role
    when 'president'
      'Você é o Presidente! Seu objetivo é sobreviver. Não esteja na mesma sala que a Bomba no final do jogo.'
    when 'bomber'
      'Você é a Bomba! Seu objetivo é estar na mesma sala que o Presidente no final do jogo para explodir!'
    when 'regular'
      team == 'blue' ? 'Ajude a proteger o Presidente! Mantenha-o longe da Bomba.' : 'Ajude a Bomba a encontrar o Presidente!'
    end
  end

  def team_mission
    case team
    when 'blue'
      '🔵 TIME AZUL: Proteja o Presidente! Garanta que ele NÃO esteja na mesma sala que a Bomba no final do jogo.'
    when 'red'
      '🔴 TIME VERMELHO: Encontre o Presidente! A Bomba deve estar na mesma sala que o Presidente no final do jogo.'
    end
  end

  def role_icon
    case role
    when 'president' then '👔'
    when 'bomber' then '💣'
    else team == 'blue' ? '🔵' : '🔴'
    end
  end

  def team_color
    team == 'blue' ? 'blue' : 'red'
  end

  def leave_game!
    update!(game: nil, team: nil, role: nil, room: nil, is_creator: false, is_leader: false, is_hostage: false, leader_vote_id: nil)
  end

  private

  def generate_session_token
    self.session_token ||= SecureRandom.uuid
  end
end
