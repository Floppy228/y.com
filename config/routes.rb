Rails.application.routes.draw do
  devise_for :users, skip: [:sessions, :registrations, :passwords]
  resources :posts, only: [:create, :destroy]
  as :user do
    get "auth", to: "devise/sessions#new", as: :new_user_session
    post "auth", to: "devise/sessions#create", as: :user_session
    delete "logout", to: "devise/sessions#destroy", as: :destroy_user_session
    post "users", to: "devise/registrations#create", as: :user_registration
    get "reset_password", to: "devise/passwords#new", as: :new_user_password
    post "reset_password", to: "devise/passwords#create", as: :user_password
    get "reset_password/edit", to: "devise/passwords#edit", as: :edit_user_password
    patch "reset_password", to: "devise/passwords#update"
    put "reset_password", to: "devise/passwords#update"
  end
  get "auth/sign_up", to: redirect("/auth?auth_mode=register")

  root "pages#index"

  get "profile", to: "pages#profile"
  get "messages", to: "pages#messages"
  get "following", to: "pages#following"
  get "settings", to: "pages#settings"
  get "ai", to: "pages#ai"
  patch "settings/account", to: "pages#update_account", as: :settings_account
  patch "settings/profile", to: "pages#update_profile", as: :settings_profile
end
