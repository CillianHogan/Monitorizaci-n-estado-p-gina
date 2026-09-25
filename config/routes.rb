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

  # Páginas de estado públicas
  get 'status', to: 'public_status#index', as: :status
  get 'status/:token', to: 'public_status#show', as: :public_status

  # Reveal health status on /up
  get 'up' => 'rails/health#show', as: :rails_health_check
end
