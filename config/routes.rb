Rails.application.routes.draw do
  scope "(:locale)", locale: /en|vi/ do
    root "static_pages#home"
    get "/signup", to: "users#new"
    post "/signup", to: "users#create"
    get "/login", to: "sessions#new"
    post "/login", to: "sessions#create"
    delete "logout", to: "sessions#destroy"
    resources :account_activations, only: :edit
    resources :subjects
    resources :tests

    namespace :supervisor do
      resources :subjects, only: %i(index new create edit update destroy)
      resources :questions, only: %i(new create)
    end
  end
end
