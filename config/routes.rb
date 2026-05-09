Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations"
  }

  get "/auth", to: "pages#auth", as: :auth
  get "/profile", to: "pages#profile", as: :profile
  get "messages", to: "pages#messages", as: :messages

  devise_scope :user do
    get "/account_restore", to: "devise/passwords#new", as: :account_restore
  end

  post "/posts", to: "pages#create_post", as: :posts

  root "pages#index"
end
