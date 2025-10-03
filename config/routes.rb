Rails.application.routes.draw do
  # Routes without locale (for backwards compatibility and health checks)
  get "up" => "rails/health#show", as: :rails_health_check

  # Routes with brand slug and locale
  scope "(:brand_slug)/:locale", brand_slug: /[a-z0-9\-]+/, locale: /en|es/ do
    resource :brand, only: [ :show, :new, :edit, :update, :create ]
    get "/my-brand", to: "brands#edit", as: "my_brand"

    # Planning Display - Single Responsibility
    resource :planning, only: [ :show ] do
      member do
        get :strategy_for_month
      end
    end

    # Planning-related specialized controllers
    namespace :planning do
      # Strategy API endpoints
      resources :strategies, only: [] do
        collection do
          get :for_month
        end
      end

      # Content refinement operations
      resources :content_refinements, only: [ :create ] do
        collection do
          post :week, action: :create  # For week-specific refinements
        end
      end

      # Content details AJAX
      resource :content_details, only: [ :show ]
    end
    get "/smart-planning", to: "plannings#smart_planning", as: "smart_planning"

    resources :reels, only: [ :index, :new, :create, :show, :edit ] do
      collection do
        get "scene-based", to: "reels#new", defaults: { template: "only_avatars" }, as: :scene_based
        get "narrative", to: "reels#new", defaults: { template: "narration_over_7_images" }, as: :narrative
        post "scene-based", to: "reels#create", defaults: { template: "only_avatars" }
        post "narrative", to: "reels#create", defaults: { template: "narration_over_7_images" }
        get "new/:template", to: "reels#new", as: :new_template
      end
    end

    resource :viral_ideas, only: [ :show ]
    resource :auto_creation, only: [ :show ]
    resource :analytics, only: [ :show ]
    resource :community, only: [ :show ]
    resource :settings, only: [ :show, :update ] do
      member do
        post :validate_heygen_api
      end
    end

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

  # Routes without brand slug for initial access and fallbacks
  scope "/:locale", locale: /en|es/ do
    get "/", to: "home#show", as: "locale_root"
    get "/select-brand", to: "brand_selection#show", as: "select_brand"
  end

  # Default root without locale or brand (shows landing page)
  get "/", to: "home#show", constraints: lambda { |req| req.format.html? }


  if Rails.env.development?
    # Enable ViewComponent previews at /rails/view_components
    mount ViewComponent::Engine, at: "/rails/view_components"
  end
end
