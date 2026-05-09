class PagesController < ApplicationController
  skip_before_action :require_login, only: [:auth]
  before_action :redirect_authenticated_user_from_auth, only: [:auth]

  def index
    @posts = []
  end

  def auth
    @auth_mode = normalized_auth_mode
  end

  def profile
    @user = current_user
    @posts = []
  end

  def messages

  end

  def ai

  end

  def create_post
    redirect_to root_path, notice: "Post publishing will be added soon."
  end

  private

  def redirect_authenticated_user_from_auth
    redirect_to root_path if user_signed_in?
  end

  def normalized_auth_mode
    params[:auth_mode].to_s == "register" ? "register" : "login"
  end
end
