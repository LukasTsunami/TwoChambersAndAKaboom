Rails.application.routes.draw do
  root 'home#index'

  resources :players, only: [:create, :update] do
    collection do
      get :check_name
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
      post :select_hostages
      post :exchange
      delete :leave
      post :timer_expired
    end
  end

  # Admin routes
  get 'admin/reset_pin', to: 'admin#reset_pin', as: :admin_reset_pin
  post 'admin/reset_pin', to: 'admin#do_reset_pin'

  # Health check
  get 'up' => 'rails/health#show', as: :rails_health_check
end
