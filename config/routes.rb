Rails.application.routes.draw do
  mount ActionCable.server => '/cable'

  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations",
    passwords: "users/passwords"
  }

  get "/auth", to: "pages#auth", as: :auth
  get "/profile", to: "pages#profile", as: :profile
  get "/users/:id", to: "pages#user_profile", as: :user

  # Сообщения
  get "/messages", to: "messages#messages", as: :messages
  post "/messages", to: "messages#create_message", as: :create_message
  post "/messages/read", to: "messages#mark_messages_read", as: :mark_messages_read
  delete "/messages/delete_chat", to: "messages#delete_messages_chat", as: :delete_messages_chat
  delete "/messages/clear", to: "messages#clear_messages_chat", as: :clear_messages_chat
  patch "/messages/:id", to: "messages#update_message", as: :update_message
  delete "/messages/:id", to: "messages#destroy_message", as: :destroy_message

  get "/ai", to: "pages#ai", as: :ai
  post "/ai/ask", to: "pages#ai_ask", as: :ai_ask
  delete "/ai/clear", to: "pages#clear_ai_chat", as: :clear_ai_chat

  get "/following", to: "pages#following", as: :following

  # Настройки
  get "/settings", to: "pages#settings", as: :settings
  get "/settings/password_reset", to: "pages#password_reset", as: :settings_password_reset
  post "/settings/password_reset/send_code", to: "pages#send_password_change_code", as: :settings_password_reset_send_code
  patch "/settings/password_reset", to: "pages#update_password_from_settings", as: :settings_password_reset_update
  patch "/settings/account", to: "pages#update_settings_account", as: :settings_account
  patch "/settings/profile", to: "pages#update_settings_profile", as: :settings_profile
  patch "/settings/chats", to: "pages#update_settings_chats", as: :settings_chats

  devise_scope :user do
    get "/account_restore", to: "users/passwords#new", as: :account_restore
    post "/account_restore", to: "pages#send_password_reset_instructions", as: :account_restore_send
  end

  # Посты
  get "/posts/:id", to: "pages#show_post", as: :post
  post "/posts", to: "pages#create_post", as: :posts
  post "/posts/:id/like", to: "pages#like_post", as: :like_post
  delete "/posts/:id/like", to: "pages#unlike_post", as: :unlike_post
  post "/posts/:id/comments", to: "pages#create_comment", as: :post_comments
  post "/posts/share", to: "pages#share_post", as: :share_post

  get "/chat_users", to: "messages#chat_users", as: :chat_users

  # Дружба
  post "/friendships/:id", to: "friendships#create", as: :send_friend_request
  patch "/friendships/:id/accept", to: "friendships#accept", as: :accept_friend_request
  delete "/friendships/:id", to: "friendships#reject", as: :reject_friend_request
  delete "/friendships/:id/unfriend", to: "friendships#unfriend", as: :unfriend

  # Уведомления
  get "/notifications", to: "notifications#index", as: :notifications
  post "/notifications/read", to: "notifications#mark_read", as: :mark_notifications_read

  # Блокировка
  post "/users/:id/block", to: "blocks#create", as: :block_user
  delete "/users/:id/unblock", to: "blocks#destroy", as: :unblock_user

  # Админка
  get "/admin", to: "admin#index", as: :admin
  post "/admin/users/:id/toggle_admin", to: "admin#toggle_admin", as: :toggle_admin
  post "/admin/users/:id/ban", to: "admin#ban", as: :ban_user
  post "/admin/users/:id/unban", to: "admin#unban", as: :unban_user
  delete "/admin/users/:id", to: "admin#destroy_user", as: :admin_destroy_user
  delete "/admin/posts/:id", to: "admin#destroy_post", as: :admin_destroy_post

  root "pages#index"
end
