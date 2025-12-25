# frozen_string_literal: true

module RoleDefinitions
  extend ActiveSupport::Concern

  # Definição de todos os roles do jogo Two Rooms and a Boom
  ROLES = {
    # ==================== TIME AZUL ====================
    president: {
      name: 'Presidente',
      team: 'blue',
      icon: '👔',
      description: 'Você é o Presidente! Seu objetivo é sobreviver. Não esteja na mesma sala que a Bomba no final do jogo.',
      ability: nil,
      required: true,
      category: :core
    },
    doctor: {
      name: 'Médico',
      team: 'blue',
      icon: '⚕️',
      description: 'Você precisa fazer card share com o Presidente antes do final do jogo, ou o time azul perde.',
      ability: :must_share_with_president,
      required: false,
      category: :special_blue
    },
    agent: {
      name: 'Agente',
      team: 'blue',
      icon: '🕵️',
      description: 'Uma vez por rodada, você pode revelar sua carta em privado e forçar um jogador a fazer card share com você.',
      ability: :force_card_share,
      required: false,
      category: :special_blue
    },
    soldier: {
      name: 'Soldado',
      team: 'blue',
      icon: '🎖️',
      description: 'Seu voto conta duas vezes na escolha de líder.',
      ability: :double_vote,
      required: false,
      category: :special_blue
    },
    citizen_blue: {
      name: 'Cidadão',
      team: 'blue',
      icon: '🔵',
      description: 'Você é um cidadão comum do time azul. Ajude a proteger o Presidente!',
      ability: nil,
      required: false,
      category: :generic
    },
    spy_blue: {
      name: 'Espião',
      team: 'blue',
      icon: '🔴',
      description: 'Você conta como membro do time vermelho, mesmo que sua cor seja azul. Ajude a Bomba!',
      ability: :counts_as_enemy,
      actual_team: 'red',
      required: false,
      category: :generic
    },
    mime_blue: {
      name: 'Mímico',
      team: 'blue',
      icon: '🤐',
      description: 'Você não pode falar, apenas se comunicar com gestos.',
      ability: :cannot_speak,
      required: false,
      category: :generic
    },
    usurper_blue: {
      name: 'Usurpadora',
      team: 'blue',
      icon: '👑',
      description: 'Uma vez por jogo, na votação para líder e antes da última rodada, você pode revelar sua carta e se tornar líder da sua sala.',
      ability: :become_leader,
      required: false,
      category: :generic
    },
    kangaroo_blue: {
      name: 'Canguru',
      team: 'blue',
      icon: '🦘',
      description: 'Uma vez por jogo, na etapa de discussão, você pode revelar sua carta e ir imediatamente para a outra sala.',
      ability: :switch_room,
      required: false,
      category: :generic
    },
    gargoyle_blue: {
      name: 'Gárgula',
      team: 'blue',
      icon: '🗿',
      description: 'Você pode escolher não ser mandado como refém para a outra sala. Outro jogador deve ir no seu lugar.',
      ability: :refuse_hostage,
      required: false,
      category: :generic
    },
    pirate_blue: {
      name: 'Pirata',
      team: 'blue',
      icon: '🏴‍☠️',
      description: 'Uma vez por jogo, antes da última rodada, você pode escolher um jogador para ser obrigado a ser mandado como refém.',
      ability: :force_hostage,
      required: false,
      category: :generic
    },
    enlisted_blue: {
      name: 'Alistado',
      team: 'blue',
      icon: '🙋',
      description: 'Uma vez por jogo, antes da última rodada, você pode escolher a si mesmo para ser mandado como refém.',
      ability: :volunteer_hostage,
      required: false,
      category: :generic
    },

    # ==================== TIME VERMELHO ====================
    bomber: {
      name: 'Bomba',
      team: 'red',
      icon: '💣',
      description: 'Você é a Bomba! Seu objetivo é estar na mesma sala que o Presidente no final do jogo para explodir!',
      ability: nil,
      required: true,
      category: :core
    },
    dr_boom: {
      name: 'Dr. Boom',
      team: 'red',
      icon: '🧨',
      description: 'Se você fizer card share com o Presidente, o jogo acaba imediatamente e o time vermelho vence.',
      ability: :instant_win_on_president_share,
      required: false,
      category: :special_red
    },
    engineer: {
      name: 'Engenheiro',
      team: 'red',
      icon: '🔧',
      description: 'Você precisa fazer card share com a Bomba antes do final do jogo, ou a bomba não é armada e o time vermelho perde.',
      ability: :must_share_with_bomber,
      required: false,
      category: :special_red
    },
    fanatic: {
      name: 'Fanático Religioso',
      team: 'red',
      icon: '⛪',
      description: 'Você só ganha se estiver na sala onde a bomba explode no final do jogo.',
      ability: :win_in_explosion,
      required: false,
      category: :special_red
    },
    citizen_red: {
      name: 'Cidadão',
      team: 'red',
      icon: '🔴',
      description: 'Você é um cidadão comum do time vermelho. Ajude a Bomba a encontrar o Presidente!',
      ability: nil,
      required: false,
      category: :generic
    },
    spy_red: {
      name: 'Espião',
      team: 'red',
      icon: '🔵',
      description: 'Você conta como membro do time azul, mesmo que sua cor seja vermelha. Proteja o Presidente!',
      ability: :counts_as_enemy,
      actual_team: 'blue',
      required: false,
      category: :generic
    },
    mime_red: {
      name: 'Mímico',
      team: 'red',
      icon: '🤐',
      description: 'Você não pode falar, apenas se comunicar com gestos.',
      ability: :cannot_speak,
      required: false,
      category: :generic
    },
    usurper_red: {
      name: 'Usurpadora',
      team: 'red',
      icon: '👑',
      description: 'Uma vez por jogo, na votação para líder e antes da última rodada, você pode revelar sua carta e se tornar líder da sua sala.',
      ability: :become_leader,
      required: false,
      category: :generic
    },
    kangaroo_red: {
      name: 'Canguru',
      team: 'red',
      icon: '🦘',
      description: 'Uma vez por jogo, na etapa de discussão, você pode revelar sua carta e ir imediatamente para a outra sala.',
      ability: :switch_room,
      required: false,
      category: :generic
    },
    gargoyle_red: {
      name: 'Gárgula',
      team: 'red',
      icon: '🗿',
      description: 'Você pode escolher não ser mandado como refém para a outra sala. Outro jogador deve ir no seu lugar.',
      ability: :refuse_hostage,
      required: false,
      category: :generic
    },
    pirate_red: {
      name: 'Pirata',
      team: 'red',
      icon: '🏴‍☠️',
      description: 'Uma vez por jogo, antes da última rodada, você pode escolher um jogador para ser obrigado a ser mandado como refém.',
      ability: :force_hostage,
      required: false,
      category: :generic
    },
    enlisted_red: {
      name: 'Alistado',
      team: 'red',
      icon: '🙋',
      description: 'Uma vez por jogo, antes da última rodada, você pode escolher a si mesmo para ser mandado como refém.',
      ability: :volunteer_hostage,
      required: false,
      category: :generic
    },

    # ==================== TIME PRETO (ÍMPAR) ====================
    hot_potato: {
      name: 'Batata Quente',
      team: 'black',
      icon: '🥔',
      description: 'Quem fizer card share (ou até color share) troca de carta imediatamente com você.',
      ability: :swap_on_share,
      required: false,
      category: :odd_player,
      odd_only: true
    },
    gambler: {
      name: 'Apostador',
      team: 'black',
      icon: '🎰',
      description: 'No final do jogo você tenta adivinhar qual time vai ganhar. Se acertar, você ganha sozinho!',
      ability: :guess_winner,
      required: false,
      category: :odd_player,
      odd_only: true
    },
    evil_genius: {
      name: 'Gênio do Mal',
      team: 'black',
      icon: '🧠',
      description: 'Você ganha o jogo se você tiver sido líder de cada uma das salas pelo menos uma vez.',
      ability: :win_as_both_leaders,
      required: false,
      category: :odd_player,
      odd_only: true
    },
    stepfather: {
      name: 'Padrasto',
      team: 'black',
      icon: '👨‍👧‍👦',
      description: 'Revele sua carta para dois jogadores no começo do jogo. Diga "vocês são meus filhos". Você ganha se eles estiverem no mesmo quarto no final.',
      ability: :children_same_room,
      required: false,
      category: :odd_player,
      odd_only: true
    },

    # ==================== TIME VERDE (ÍMPAR) ====================
    zombie: {
      name: 'Zumbi',
      team: 'green',
      icon: '🧟',
      description: 'Você contamina jogadores que compartilharem cartas com você. Vocês ganham se terminarem numa sala só com zumbis e não estiverem sendo explodidos.',
      ability: :infect_on_share,
      required: false,
      category: :odd_player,
      odd_only: true
    }
  }.freeze

  # Categorias de roles para facilitar a seleção
  ROLE_CATEGORIES = {
    core: 'Essenciais',
    special_blue: 'Especiais Azuis',
    special_red: 'Especiais Vermelhos',
    generic: 'Genéricos (Azul/Vermelho)',
    odd_player: 'Jogador Ímpar'
  }.freeze

  # Times disponíveis
  TEAMS = {
    blue: { name: 'Azul', color: 'blue', icon: '🔵' },
    red: { name: 'Vermelho', color: 'red', icon: '🔴' },
    black: { name: 'Preto', color: 'black', icon: '⚫' },
    green: { name: 'Verde', color: 'green', icon: '🟢' }
  }.freeze

  # Modos de seleção de roles
  ROLE_SELECTION_MODES = {
    manual: 'Selecionar manualmente',
    all: 'Usar todos os roles',
    by_players: 'Baseado no número de jogadores',
    random: 'Aleatório'
  }.freeze

  class_methods do
    def role_info(role_key)
      ROLES[role_key.to_sym]
    end

    def roles_for_team(team)
      ROLES.select { |_, v| v[:team] == team.to_s }
    end

    def roles_for_category(category)
      ROLES.select { |_, v| v[:category] == category.to_sym }
    end

    def odd_player_roles
      ROLES.select { |_, v| v[:odd_only] }
    end

    def core_roles
      ROLES.select { |_, v| v[:required] }
    end

    def special_roles
      ROLES.reject { |_, v| v[:required] || v[:category] == :generic }
    end

    def generic_roles
      ROLES.select { |_, v| v[:category] == :generic }
    end

    def available_roles_for_player_count(count)
      # Roles essenciais sempre incluídos
      roles = core_roles.keys

      # Se número ímpar, adiciona um role de jogador ímpar
      if count.odd?
        roles += odd_player_roles.keys.sample(1)
      end

      # Adiciona roles especiais baseado no número de jogadores
      special_count = (count - 2) / 3 # 1 especial a cada 3 jogadores extras
      roles += special_roles.keys.sample([special_count, special_roles.size].min)

      roles.uniq
    end
  end
end

