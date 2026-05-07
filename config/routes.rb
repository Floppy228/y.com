Rails.application.routes.draw do
  devise_for :users
  get "/auth", to: "pages#auth", as: :auth

  root "pages#index"
end