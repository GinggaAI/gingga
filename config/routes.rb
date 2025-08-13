Rails.application.routes.draw do
  resource :brand, only: [ :show, :edit, :update ]
  resource :planning, only: [ :show ]
  resource :viral_ideas, only: [ :show ]
  resource :auto_creation, only: [ :show ]
  resource :analytics, only: [ :show ]
  resource :community, only: [ :show ]
  resource :settings, only: [ :show ]
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # API routes
  namespace :api do
    namespace :v1 do
      resources :api_tokens, except: [ :new, :edit ]
    end
  end

  # CREAS endpoints
  resources :creas_strategist, only: [ :create ]

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#show"


  if Rails.env.development?
    # Enable ViewComponent previews at /rails/view_components
    mount ViewComponent::Engine, at: "/rails/view_components"
  end
end
