Rails.application.routes.draw do # начало блока маршрутов
  devise_for :users # создает нужные маршруты

  # делает проверку ответа сервера
  get "up" => "rails/health#show", as: :rails_health_check

  root "rails/health#show" # главная страница
end
