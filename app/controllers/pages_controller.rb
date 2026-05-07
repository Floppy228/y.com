class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:auth]

  def index
    redirect_to auth_path unless user_signed_in?
  end

  def auth
    redirect_to root_path if user_signed_in?

    @user = User.new
  end
end