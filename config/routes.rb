Rails.application.routes.draw do
  scope "(:locale)", locale: /en|vi/ do
    root "static_pages#home"
    get "/signup", to: "users#new"
    post "/signup", to: "users#create"
    get "/login", to: "sessions#new"
    post "/login", to: "sessions#create"
    delete "logout", to: "sessions#destroy"
    resources :password_resets, only: [:new, :create, :edit, :update]
    resources :subjects
    resources :tests
    resources :users

    namespace :supervisor do
      root "static_pages#home"
      resources :subjects, only: %i(index show new create edit update destroy)
      resources :questions, only: %i(index new create edit update destroy)
      resources :users, only: :index do
        member do
          patch :activate
          patch :deactivate
        end
      end
    end
  end
end
