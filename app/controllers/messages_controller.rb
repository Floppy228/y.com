class MessagesController < ApplicationController
  def messages
    @query = params[:q].to_s.strip
    users_scope = User.where.not(id: current_user.id)
    @selected_user = users_scope.find_by(id: params[:user_id])

    chat_partner_ids = chat_partner_ids_for(current_user)
    excluded = excluded_user_ids
    chat_partner_ids.reject! { |id| excluded.include?(id) }

    @search_dms = if @query.present?
      DirectMessage
        .where("LOWER(content) LIKE :q", q: "%#{@query.downcase}%")
        .where("sender_id = :id OR recipient_id = :id", id: current_user.id)
        .includes(:sender, :recipient)
        .order(created_at: :desc)
        .limit(20)
    else
      DirectMessage.none
    end

    @direct_messages = if @selected_user
      msgs = DirectMessage.between(current_user, @selected_user).includes(:sender, :recipient)
      if @query.present?
        msgs = msgs.where("LOWER(content) LIKE :q", q: "%#{@query.downcase}%")
      end
      DirectMessage.unread_for(current_user).where(sender: @selected_user).update_all(read_at: Time.current)
      @total_unread_count = DirectMessage.unread_for(current_user).count
      broadcast_unread_badge(current_user)
      msgs
    else
      DirectMessage.none
    end

    @chat_users = users_scope.where(id: chat_partner_ids).order(:name, :username)
    @chat_rows = @chat_users.map { |user| build_chat_row(user) }
  end

  def create_message
    recipient = User.where.not(id: current_user.id).find_by(id: params[:recipient_id])
    content = params[:content].to_s.strip
    has_image = params[:image].present?

    unless recipient
      redirect_to messages_path, alert: "Выберите пользователя для чата."
      return
    end

    if current_user.blocked?(recipient) || current_user.blocked_by?(recipient)
      redirect_to messages_path, alert: "Невозможно отправить сообщение этому пользователю."
      return
    end

    if content.blank? && !has_image
      redirect_to messages_path(user_id: recipient.id), alert: "Введите сообщение или прикрепите изображение."
      return
    end

    message = current_user.sent_direct_messages.build(recipient: recipient, content: content)
    message.image.attach(params[:image]) if has_image
    message.save!
    broadcast_unread_badge(recipient)
    redirect_to messages_path(user_id: recipient.id), notice: "Сообщение отправлено."
  rescue StandardError
    redirect_to messages_path(user_id: recipient&.id), alert: "Не удалось отправить сообщение."
  end

  def update_message
    message = current_user.sent_direct_messages.find_by(id: params[:id])
    unless message
      redirect_to messages_path, alert: "Сообщение не найдено."
      return
    end
    content = params[:content].to_s.strip
    if content.blank?
      redirect_to messages_path(user_id: direct_message_partner(message).id), alert: "Текст сообщения не может быть пустым."
      return
    end
    if message.update(content: content)
      redirect_to messages_path(user_id: direct_message_partner(message).id), notice: "Сообщение изменено."
    else
      redirect_to messages_path(user_id: direct_message_partner(message).id), alert: message.errors.full_messages.to_sentence
    end
  end

  def destroy_message
    message = current_user.sent_direct_messages.find_by(id: params[:id])
    unless message
      redirect_to messages_path, alert: "Сообщение не найдено."
      return
    end
    chat_user = direct_message_partner(message)
    message.destroy
    redirect_to messages_path(user_id: chat_user.id), notice: "Сообщение удалено."
  end

  def clear_messages_chat
    clear_or_delete_messages(:clear)
  end

  def delete_messages_chat
    clear_or_delete_messages(:delete)
  end

  def mark_messages_read
    sender = User.find_by(id: params[:sender_id])
    if sender
      DirectMessage.unread_for(current_user).where(sender: sender).update_all(read_at: Time.current)
      broadcast_unread_badge(current_user)
    end
    head :ok
  end

  def chat_users
    users = User.where(id: chat_partner_ids_for(current_user)).order(:name, :username).map do |u|
      { id: u.id, name: u.name.presence || u.username, username: u.username }
    end
    render json: users
  end

  private

  def clear_or_delete_messages(action)
    selected_user = User.where.not(id: current_user.id).find_by(id: params[:user_id])
    unless selected_user
      redirect_to messages_path, alert: "Сначала выберите чат."
      return
    end

    DirectMessage.where(sender: current_user, recipient: selected_user).delete_all
    DirectMessage.where(sender: selected_user, recipient: current_user).delete_all

    if action == :clear
      dm = current_user.sent_direct_messages.build(recipient: selected_user, content: "")
      dm.save!(validate: false)
      redirect_to messages_path(user_id: selected_user.id), notice: "Чат очищен."
    else
      redirect_to messages_path, notice: "Чат удалён."
    end
  rescue StandardError => e
    Rails.logger.error "=== clear_or_delete_messages error: #{e.class}: #{e.message} ==="
    redirect_to messages_path, alert: "Ошибка: #{e.message}"
  end

  def build_chat_row(user)
    last_message = DirectMessage.between(current_user, user).last
    preview = if last_message
      if last_message.image.attached? && last_message.content.blank?
        "Изображение"
      elsif last_message.image.attached?
        "#{last_message.content}"
      else
        last_message.content.presence || "Чат очищен"
      end
    else
      "Чат ещё не начат"
    end

    {
      user: user,
      preview: preview,
      time: last_message&.created_at,
      active: @selected_user&.id == user.id,
      unread_count: DirectMessage.unread_for(current_user).where(sender: user).count
    }
  end

  def direct_message_partner(message)
    message.sender_id == current_user.id ? message.recipient : message.sender
  end

  def chat_partner_ids_for(user)
    DirectMessage
      .where("sender_id = :id OR recipient_id = :id", id: user.id)
      .pluck(:sender_id, :recipient_id).flatten.uniq
      .reject { |id| id == user.id }
  end
end
