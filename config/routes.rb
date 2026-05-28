Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations"
  }

  get "/auth", to: "pages#auth", as: :auth
  get "/profile", to: "pages#profile", as: :profile
  get "/messages", to: "pages#messages", as: :messages
  get "/ai", to: "pages#ai", as: :ai
  post "/ai/ask", to: "pages#ai_ask", as: :ai_ask
  delete "/ai/clear", to: "pages#clear_ai_chat", as: :clear_ai_chat
  get "/following", to: "pages#following", as: :following
  delete "/messages/clear", to: "pages#clear_messages_chat", as: :clear_messages_chat
  get "/settings", to: "pages#settings", as: :settings
  patch "/settings/account", to: "pages#update_settings_account", as: :settings_account
  patch "/settings/profile", to: "pages#update_settings_profile", as: :settings_profile

  devise_scope :user do
    get "/account_restore", to: "devise/passwords#new", as: :account_restore
  end

  post "/posts", to: "pages#create_post", as: :posts

  root "pages#index"
end
