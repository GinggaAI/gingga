Rails.application.routes.draw do
  # Routes without locale (for backwards compatibility and health checks)
  get "up" => "rails/health#show", as: :rails_health_check

  # Routes with optional locale scope
  scope "(:locale)", locale: /en|es/ do
    resource :brand, only: [ :show, :edit, :update ]
    get "/my-brand", to: "brands#edit", as: "my_brand"

    resource :planning, only: [ :show ] do
      member do
        get :strategy_for_month
        post :voxa_refine
      end
    end
    get "/smart-planning", to: "plannings#smart_planning", as: "smart_planning"

    resources :reels, only: [ :index, :new, :create, :show ] do
      collection do
        get "scene-based", to: "reels#scene_based"
        post "scene-based", to: "reels#create_scene_based"
        get "narrative", to: "reels#narrative"
        post "narrative", to: "reels#create_narrative"
      end
    end

    resource :viral_ideas, only: [ :show ]
    resource :auto_creation, only: [ :show ]
    resource :analytics, only: [ :show ]
    resource :community, only: [ :show ]
    resource :settings, only: [ :show ]

    # Defines the root path route ("/")
    root "home#show"
  end

  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations",
    passwords: "users/passwords"
  }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # API routes
  namespace :api do
    namespace :v1 do
      resources :api_tokens, except: [ :new, :edit ]
      resources :categories, only: [ :index ]
      resources :formats, only: [ :index ]
    end
  end

  # CREAS endpoints
  resources :creas_strategist, only: [ :create ]
  resources :creas_strategy_plans, only: [ :show ], path: "creas_strategy_plans"

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Default root without locale (redirects to home)
  get "/", to: redirect("/#{I18n.default_locale}"), constraints: lambda { |req| req.format.html? }


  if Rails.env.development?
    # Enable ViewComponent previews at /rails/view_components
    mount ViewComponent::Engine, at: "/rails/view_components"
  end
end
