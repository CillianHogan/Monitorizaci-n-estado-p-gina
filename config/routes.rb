# frozen_string_literal: true

Rails.application.routes.draw do
  resources :notification_channels, only: [:index, :create, :destroy] do
    member do
      patch :set_default
    end
  end

  devise_for :users
  resources :domains do
    member do
      post :check_status
      get :export_csv
    end
  end
  resources :api_endpoints do
    member do
      post :check_status
      get :export_csv
    end
  end
  root 'home#index'

  # Páginas de estado públicas
  get 'status', to: 'public_status#index', as: :status
  get 'status/:token', to: 'public_status#show', as: :public_status

  # Reveal health status on /up
  get 'up' => 'rails/health#show', as: :rails_health_check
end
