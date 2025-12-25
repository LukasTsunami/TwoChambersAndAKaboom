Rails.application.routes.draw do
  root 'home#index'

  resources :players, only: [:create, :update] do
    collection do
      get :check_name
      post :validate_pin
    end
  end

  resources :games, only: [:new, :create, :show] do
    collection do
      get :join
      post :enter
    end

    member do
      post :start
      post :select_leader
      post :usurp_leadership
      post :select_hostages
      post :gargoyle_decision
      post :exchange
      post :exit_game
      delete :abandon
      delete :destroy_room
      post :timer_expired
    end

    resources :card_shares, only: [:index, :create] do
      member do
        post :accept
        post :reject
      end
    end

    post :ability, on: :member
  end

  # Admin routes
  get 'admin/reset-pin', to: 'admin#reset_pin', as: :admin_reset_pin
  post 'admin/reset-pin', to: 'admin#do_reset_pin'

  get 'admin/reset-room', to: 'admin#reset_room', as: :admin_reset_room
  post 'admin/reset-room', to: 'admin#do_reset_room'

  get 'admin/reset-player', to: 'admin#reset_player', as: :admin_reset_player
  post 'admin/reset-player', to: 'admin#do_reset_player'

  # Health check
  get 'up' => 'rails/health#show', as: :rails_health_check
end
