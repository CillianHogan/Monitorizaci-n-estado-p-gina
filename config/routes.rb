# frozen_string_literal: true

Rails.application.routes.draw do
  resources :notification_channels, only: [:index, :create, :destroy] do
    member do
      patch :set_default
    end
  end

  devise_for :users, controllers: { registrations: "users/registrations" }
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
  get 'pricing', to: 'home#pricing', as: :pricing

  # Páginas de estado públicas
  get 'status', to: 'public_status#index', as: :status
  get 'status/:token', to: 'public_status#show', as: :public_status

  # Reveal health status on /up
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Pasarela de pago Stripe (Modo Test)
  resource :checkout, only: [:create] do
    get :success
    get :cancel
    get :portal
  end
  post "webhooks/stripe", to: "webhooks#stripe"
end