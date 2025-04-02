# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users
  resources :domains do
    member do
      post :check_status
    end
  end
  resources :api_endpoints do
    member do
      post :check_status
    end
  end
  root 'home#index'

  # Ruta para la página de estado pública
  get 'status/:token', to: 'public_status#show', as: :public_status

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check
end
