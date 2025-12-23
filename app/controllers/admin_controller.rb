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
end
