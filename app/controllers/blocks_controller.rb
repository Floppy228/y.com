class BlocksController < ApplicationController
  def create
    user = User.find(params[:id])
    if current_user == user
      redirect_back fallback_location: root_path, alert: "Нельзя заблокировать самого себя."
      return
    end
    current_user.block(user)
    redirect_back fallback_location: root_path, notice: "Пользователь заблокирован."
  end

  def destroy
    user = User.find(params[:id])
    current_user.unblock(user)
    redirect_back fallback_location: root_path, notice: "Пользователь разблокирован."
  end
end
