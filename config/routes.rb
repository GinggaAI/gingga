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
        post :voxa_refine_week
      end
    end
    get "/smart-planning", to: "plannings#smart_planning", as: "smart_planning"

    resources :reels, only: [ :index, :new, :create, :show ] do
      collection do
        get "scene-based", to: "reels#new", defaults: { template: "solo_avatars" }, as: :scene_based
        get "narrative", to: "reels#new", defaults: { template: "narration_over_7_images" }, as: :narrative
        post "scene-based", to: "reels#create", defaults: { template: "solo_avatars" }
        post "narrative", to: "reels#create", defaults: { template: "narration_over_7_images" }
        get "new/:template", to: "reels#new", as: :new_template
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
  resources :strategy_plan_status, only: [ :show ]

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
