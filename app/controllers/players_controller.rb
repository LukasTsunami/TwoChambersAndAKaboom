class PlayersController < ApplicationController
  def create
    name = params[:name].to_s.strip

    if name.blank?
      redirect_to root_path, alert: 'Nome não pode estar vazio.'
      return
    end

    player = Player.create!(name: name)
    session[:player_id] = player.id

    if params[:action_type] == 'create'
      redirect_to new_game_path
    else
      redirect_to join_games_path
    end
  end
end

