class AdminController < ApplicationController
  def reset_pin
    @players = Player.order(:name)
  end

  def do_reset_pin
    name = params[:name].to_s.strip

    if name.blank?
      redirect_to admin_reset_pin_path, alert: 'Nome não pode estar vazio.'
      return
    end

    player = Player.find_by(name: name)

    if player.nil?
      redirect_to admin_reset_pin_path, alert: 'Jogador não encontrado.'
      return
    end

    player.reset_pin!
    redirect_to admin_reset_pin_path, notice: "PIN de '#{player.name}' resetado para 000."
  end

  def reset_room
    @games = Game.order(created_at: :desc)
  end

  def do_reset_room
    code = params[:code].to_s.strip.upcase

    if code.blank?
      redirect_to admin_reset_room_path, alert: 'Código da sala não pode estar vazio.'
      return
    end

    game = Game.find_by(code: code)

    if game.nil?
      redirect_to admin_reset_room_path, alert: 'Sala não encontrada.'
      return
    end

    player_count = game.players.count
    game.destroy
    redirect_to admin_reset_room_path, notice: "Sala '#{code}' apagada com sucesso! (#{player_count} jogadores foram removidos)"
  end

  def reset_player
    @players = Player.order(:name)
  end

  def do_reset_player
    name = params[:name].to_s.strip

    if name.blank?
      redirect_to admin_reset_player_path, alert: 'Nome não pode estar vazio.'
      return
    end

    player = Player.find_by(name: name)

    if player.nil?
      redirect_to admin_reset_player_path, alert: 'Jogador não encontrado.'
      return
    end

    player.destroy
    redirect_to admin_reset_player_path, notice: "Jogador '#{name}' apagado com sucesso!"
  end
end
