class HomeController < ApplicationController
  def index
    if current_player&.game
      redirect_to game_path(current_player.game)
    end
  end
end

