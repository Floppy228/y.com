class PagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:profile, :settings, :update_account, :update_profile]

  def index
  end

  def profile
  end

  def messages
  end

  def following
  end

  def settings
  end

  def ai
  end

  def update_account
    if @user.update(account_params)
      redirect_to settings_path, notice: "Данные аккаунта сохранены."
    else
      redirect_to settings_path(anchor: "account-section"), alert: @user.errors.full_messages.to_sentence
    end
  end

  def update_profile
    if @user.update(profile_params)
      redirect_to settings_path(anchor: "profile-section"), notice: "Профиль обновлен."
    else
      redirect_to settings_path(anchor: "profile-section"), alert: @user.errors.full_messages.to_sentence
    end
  end

  private

  def set_user
    @user = current_user
  end

  def account_params
    params.require(:user).permit(:name, :username, :email)
  end

  def profile_params
    params.require(:user).permit(:name, :bio)
  end
end
