class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :current_player

  rescue_from ActionController::InvalidAuthenticityToken, with: :handle_invalid_token

  private

  def current_player
    return @current_player if defined?(@current_player)

    if session[:player_id]
      @current_player = Player.find_by(id: session[:player_id])
    end
  end

  def require_player!
    unless current_player
      redirect_to root_path, alert: 'Por favor, entre com seu nome primeiro.'
    end
  end

  def require_game!
    unless current_player&.game
      redirect_to root_path, alert: 'Você não está em nenhum jogo.'
    end
  end

  def handle_invalid_token
    session.delete(:player_id)
    redirect_to root_path, alert: 'Sua sessão expirou. Por favor, entre novamente.'
  end
end
