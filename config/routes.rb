Rails.application.routes.draw do
  root 'home#index'

  resources :players, only: [:create]

  resources :games, only: [:new, :create, :show] do
    collection do
      get :join
      post :enter
    end

    member do
      post :start
      post :select_leader
      post :select_hostages
      post :exchange
      delete :leave
      post :timer_expired
    end
  end

  # Health check
  get 'up' => 'rails/health#show', as: :rails_health_check
end
