class FriendshipsController < ApplicationController
  def create
    friend = User.find(params[:id])
    if current_user == friend
      redirect_back fallback_location: root_path, alert: "Нельзя отправить запрос самому себе."
      return
    end

    if current_user.pending_friend_request_to?(friend)
      redirect_back fallback_location: root_path, alert: "Запрос уже отправлен."
      return
    end

    if current_user.pending_friend_request_from?(friend)
      redirect_back fallback_location: root_path, alert: "Пользователь уже отправил вам запрос."
      return
    end

    friendship = current_user.friendships.build(friend: friend, status: "pending")
    if friendship.save
      create_notification(user: friend, actor: current_user, notifiable: friendship, action: "friend_request")
      redirect_back fallback_location: root_path, notice: "Запрос в друзья отправлен."
    else
      redirect_back fallback_location: root_path, alert: friendship.errors.full_messages.to_sentence
    end
  end

  def accept
    friendship = current_user.inverse_friendships.find_by(user_id: params[:id], status: "pending")
    unless friendship
      redirect_back fallback_location: root_path, alert: "Запрос не найден."
      return
    end

    friendship.update!(status: "accepted")
    create_notification(user: friendship.user, actor: current_user, notifiable: friendship, action: "friend_accept")
    redirect_back fallback_location: root_path, notice: "Запрос принят."
  end

  def reject
    friendship = current_user.inverse_friendships.find_by(user_id: params[:id], status: "pending")
    unless friendship
      redirect_back fallback_location: root_path, alert: "Запрос не найден."
      return
    end

    friendship.destroy
    redirect_back fallback_location: root_path, notice: "Запрос отклонён."
  end

  def unfriend
    friendship = current_user.friendships.find_by(friend_id: params[:id], status: "accepted") ||
                 current_user.inverse_friendships.find_by(user_id: params[:id], status: "accepted")
    unless friendship
      redirect_back fallback_location: root_path, alert: "Вы не в друзьях с этим пользователем."
      return
    end
    friendship.destroy
    redirect_back fallback_location: root_path, notice: "Пользователь удалён из друзей."
  end
end
