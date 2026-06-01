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
  get "/messages", to: "pages#messages", as: :messages
  post "/messages", to: "pages#create_message", as: :create_message
  post "/messages/read", to: "pages#mark_messages_read", as: :mark_messages_read
  delete "/messages/clear", to: "pages#clear_messages_chat", as: :clear_messages_chat
  patch "/messages/:id", to: "pages#update_message", as: :update_message
  delete "/messages/:id", to: "pages#destroy_message", as: :destroy_message
  get "/ai", to: "pages#ai", as: :ai
  post "/ai/ask", to: "pages#ai_ask", as: :ai_ask
  delete "/ai/clear", to: "pages#clear_ai_chat", as: :clear_ai_chat
  get "/following", to: "pages#following", as: :following
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

  get "/posts/:id", to: "pages#show_post", as: :post
  post "/posts", to: "pages#create_post", as: :posts
  post "/posts/:id/like", to: "pages#like_post", as: :like_post
  delete "/posts/:id/like", to: "pages#unlike_post", as: :unlike_post
  post "/posts/:id/comments", to: "pages#create_comment", as: :post_comments
  post "/posts/share", to: "pages#share_post", as: :share_post
  get "/chat_users", to: "pages#chat_users", as: :chat_users

  # Friendships
  post "/friendships/:id", to: "pages#send_friend_request", as: :send_friend_request
  patch "/friendships/:id/accept", to: "pages#accept_friend_request", as: :accept_friend_request
  delete "/friendships/:id", to: "pages#reject_friend_request", as: :reject_friend_request
  delete "/friendships/:id/unfriend", to: "pages#unfriend", as: :unfriend

  # Notifications
  get "/notifications", to: "pages#notifications", as: :notifications
  post "/notifications/read", to: "pages#mark_notifications_read", as: :mark_notifications_read

  # Blocks
  post "/users/:id/block", to: "pages#block_user", as: :block_user
  delete "/users/:id/unblock", to: "pages#unblock_user", as: :unblock_user

  root "pages#index"
end
