Rails.application.routes.draw do
  devise_for :users

  get "/auth", to: "pages#auth", as: :auth

  devise_scope :user do
    get "/account_restore", to: "devise/passwords#new", as: :account_restore
  end

  root "pages#index"
end