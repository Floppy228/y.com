class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:auth]
  before_action :redirect_authenticated_user_from_auth, only: [:auth]

  def index
    return if user_signed_in?

    redirect_to auth_path
  end

  def auth
    @auth_mode = normalized_auth_mode
  end

  private

  def redirect_authenticated_user_from_auth
    redirect_to root_path if user_signed_in?
  end

  def normalized_auth_mode
    params[:auth_mode].to_s == "register" ? "register" : "login"
  end
end
