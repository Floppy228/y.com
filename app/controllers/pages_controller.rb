class PagesController < ApplicationController
  skip_before_action :require_login, only: [:auth]
  before_action :redirect_authenticated_user_from_auth, only: [:auth]

  def index
    @posts = Post.includes(:user).order(created_at: :desc)
  end

  def auth
    @auth_mode = normalized_auth_mode
  end

  def profile
    @user = current_user
    @posts = current_user.posts.order(created_at: :desc)
  end

  def messages
  end

  def ai
  end

  def following
  end

  def settings
    @user = current_user
  end

  def update_settings_account
    @user = current_user

    if @user.update(filtered_user_params(:username, :name, :email))
      redirect_to settings_path, notice: "Настройки аккаунта сохранены."
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :settings, status: :unprocessable_entity
    end
  end

  def update_settings_profile
    @user = current_user

    if @user.update(filtered_user_params(:name, :bio, :birthday))
      redirect_to settings_path, notice: "Профиль сохранен."
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :settings, status: :unprocessable_entity
    end
  end

  def create_post
    post = current_user.posts.new(content: params[:post][:content])

    if post.save
      redirect_to root_path, notice: "Пост опубликован!"
    else
      redirect_to root_path, alert: post.errors.full_messages.to_sentence
    end
  end

  private

  def redirect_authenticated_user_from_auth
    redirect_to root_path if user_signed_in?
  end

  def normalized_auth_mode
    params[:auth_mode].to_s == "register" ? "register" : "login"
  end

  def filtered_user_params(*keys)
    allowed = keys.map(&:to_s) & User.attribute_names
    params.fetch(:user, {}).permit(*allowed)
  end
end