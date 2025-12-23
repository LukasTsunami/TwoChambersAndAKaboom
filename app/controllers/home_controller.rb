class HomeController < ApplicationController
  def index
    # Não limpa sessão automaticamente - só limpa ao sair/apagar sala
    # Isso permite que o jogador continue logado após criar/entrar em sala

    # Se já está logado e em um jogo, redireciona
    if current_player&.game
      redirect_to game_path(current_player.game)
    end
  end
end
