Rails.application.routes.draw do
  # Pipeline builder routes
  resources :pipeline_builders, only: [:new, :edit, :create, :update] do
    member do
      get :load_pipeline
    end
  end

  # API endpoints for pipeline operations
  namespace :api do
    resources :pipelines, only: [:create, :update] do
      member do
        post :run
        post :stop
        get :status
      end
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "pipeline_builders#new"
end
