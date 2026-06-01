class PagesController < ApplicationController
  skip_before_action :require_login, only: [:auth, :send_password_reset_instructions]
  before_action :redirect_authenticated_user_from_auth, only: [:auth]

  def index
    @posts = Post.includes(:user, :likes, comments: :user).order(created_at: :desc)
  end

  def auth
    @auth_mode = normalized_auth_mode
  end

  def profile
    @user = current_user
    @posts = current_user.posts.includes(:likes, comments: :user).order(created_at: :desc)
  end

  def user_profile
    @user = User.find(params[:id])
    @posts = @user.posts.includes(:likes, comments: :user).order(created_at: :desc)
    render :profile
  end

  def messages
    @query = params[:q].to_s.strip
    users_scope = User.where.not(id: current_user.id)
    @selected_user = users_scope.find_by(id: params[:user_id])

    chat_user_ids = DirectMessage
      .where("sender_id = :id OR recipient_id = :id", id: current_user.id)
      .pluck(:sender_id, :recipient_id)
      .flatten
      .uniq
      .reject { |id| id == current_user.id }

    @chat_users = users_scope.where(id: chat_user_ids).order(:name, :username)
    @chat_rows = @chat_users.map { |user| build_chat_row(user) }

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
      msgs = DirectMessage.between(current_user, @selected_user)
      if @query.present?
        msgs = msgs.where("LOWER(content) LIKE :q", q: "%#{@query.downcase}%")
      end
      DirectMessage.unread_for(current_user).where(sender: @selected_user).update_all(read_at: Time.current)
      msgs
    else
      DirectMessage.none
    end
  end

  def ai
    @ai_query = params[:q].to_s.strip
    @ai_messages = current_user.ai_messages.order(:created_at)
    if @ai_query.present?
      @ai_messages = @ai_messages.where("LOWER(content) LIKE :q", q: "%#{@ai_query.downcase}%")
    end
  end

  def ai_ask
    prompt = params[:prompt].to_s.strip
    if prompt.blank?
      redirect_to ai_path, alert: "Введите вопрос для Y-Core."
      return
    end

    current_user.ai_messages.create!(role: "user", content: prompt)
    answer = DeepseekClient.chat(prompt: prompt)
    current_user.ai_messages.create!(role: "assistant", content: answer)
    redirect_to ai_path
  rescue StandardError => e
    redirect_to ai_path, alert: "Y-Core: #{e.message}"
  end

  def clear_ai_chat
    current_user.ai_messages.delete_all
    redirect_to ai_path, notice: "Чат Y-Core очищен."
  end

  def clear_messages_chat
    selected_user = User.where.not(id: current_user.id).find_by(id: params[:user_id])
    unless selected_user
      redirect_to messages_path, alert: "Сначала выберите чат."
      return
    end

    DirectMessage.between(current_user, selected_user).delete_all
    redirect_to messages_path(user_id: selected_user.id), notice: "Чат очищен."
  end

  def mark_messages_read
    sender = User.find_by(id: params[:sender_id])
    if sender
      DirectMessage.unread_for(current_user).where(sender: sender).update_all(read_at: Time.current)
      unread_count = DirectMessage.unread_for(current_user).count
      badge_html = render_to_string(partial: "layouts/unread_badge", locals: { count: unread_count })
      Turbo::StreamsChannel.broadcast_replace_to "messages_user_#{current_user.id}", target: "unread-badge", html: badge_html
    end
    head :ok
  end

  def following
    @query = params[:q].to_s.strip
    @age_from = params[:age_from].to_s.strip.presence
    @age_to = params[:age_to].to_s.strip.presence

    @users = User.where.not(id: current_user.id)

    if @query.present?
      @users = @users.where("LOWER(name) LIKE :q OR LOWER(username) LIKE :q", q: "%#{@query.downcase}%")
    end

    if @age_from.present?
      max_birthday = Date.today - @age_from.to_i.years
      @users = @users.where("birthday <= ?", max_birthday)
    end

    if @age_to.present?
      min_birthday = Date.today - (@age_to.to_i + 1).years + 1.day
      @users = @users.where("birthday >= ?", min_birthday)
    end

    @users = @users.order(:name, :username)
    @users = User.none if @query.blank? && @age_from.blank? && @age_to.blank?
  end

  def create_message
    recipient = User.where.not(id: current_user.id).find_by(id: params[:recipient_id])
    content = params[:content].to_s.strip
    has_image = params[:image].present?

    unless recipient
      redirect_to messages_path, alert: "Выберите пользователя для чата."
      return
    end

    if content.blank? && !has_image
      redirect_to messages_path(user_id: recipient.id), alert: "Введите сообщение или прикрепите изображение."
      return
    end

    message = current_user.sent_direct_messages.build(recipient: recipient, content: content)
    message.image.attach(params[:image]) if has_image
    message.save!
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

  def settings
    @user = current_user
  end

  def password_reset
    @user = current_user
  end

  def send_password_reset_instructions
    unless mailer_configured?
      redirect_to account_restore_path, alert: "Почта не настроена. Заполните SMTP-поля в .env."
      return
    end

    email = params.dig(:user, :email).to_s.strip
    user = User.find_by(email: email)

    unless user
      redirect_to account_restore_path, alert: "Пользователь с таким email не найден."
      return
    end

    user.send_reset_password_instructions

    redirect_to account_restore_path, notice: "Инструкции по сбросу пароля отправлены на ваш email."
  rescue StandardError => e
    Rails.logger.error "Password reset error: #{e.message}"
    redirect_to account_restore_path, alert: "Не удалось отправить письмо. Проверьте SMTP-настройки."
  end

  def send_password_change_code
    unless mailer_configured?
      redirect_to settings_password_reset_path, alert: "Почта не настроена. Заполните SMTP-поля в .env."
      return
    end

    code = format("%06d", rand(0..999_999))
    session[:password_change_code] = code
    session[:password_change_code_sent_at] = Time.current.to_i

    PasswordCodeMailer.change_password_code(current_user, code).deliver_now
    redirect_to settings_password_reset_path, notice: "Код отправлен на #{current_user.email}."
  rescue StandardError
    redirect_to settings_password_reset_path, alert: "Не удалось отправить письмо. Проверьте SMTP-настройки в .env."
  end

  def update_password_from_settings
    code = params[:code].to_s.strip
    password = params[:password].to_s
    password_confirmation = params[:password_confirmation].to_s

    if code.blank? || password.blank? || password_confirmation.blank?
      redirect_to settings_password_reset_path, alert: "Заполните код и оба поля пароля."
      return
    end

    unless valid_password_change_code?(code)
      redirect_to settings_password_reset_path, alert: "Код неверный или устарел."
      return
    end

    if current_user.update(password: password, password_confirmation: password_confirmation)
      clear_password_change_code!
      bypass_sign_in current_user
      redirect_to settings_password_reset_path, notice: "Пароль изменен."
    else
      redirect_to settings_password_reset_path, alert: current_user.errors.full_messages.to_sentence
    end
  end

  def update_settings_account
    @user = current_user

    if @user.update(filtered_user_params(:username, :email))
      redirect_to settings_path, notice: "Настройки аккаунта сохранены."
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :settings, status: :unprocessable_entity
    end
  end

  def update_settings_profile
    @user = current_user

    if @user.update(filtered_user_params(:name, :bio, :status, :birthday))
      attach_profile_images(@user)
      redirect_to settings_path, notice: "Профиль сохранен."
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :settings, status: :unprocessable_entity
    end
  end

  def update_settings_chats
    @user = current_user

    if @user.update(filtered_user_params(:message_send_shortcut))
      redirect_to settings_path, notice: "Настройки чатов сохранены."
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :settings, status: :unprocessable_entity
    end
  end

  def create_post
    post = current_user.posts.new(content: params[:post][:content])
    post.image.attach(params[:post][:image]) if params[:post][:image].present?

    if post.save
      redirect_to root_path, notice: "Пост опубликован."
    else
      redirect_to root_path, alert: post.errors.full_messages.to_sentence
    end
  end

  def like_post
    post = Post.find(params[:id])
    already_liked = current_user.likes.exists?(post: post)
    unless already_liked
      current_user.likes.create!(post: post)
      if post.user != current_user
        Notification.create!(
          user: post.user,
          actor: current_user,
          notifiable: post,
          action: "like"
        )
      end
    end
    redirect_back fallback_location: root_path
  end

  def unlike_post
    post = Post.find(params[:id])
    current_user.likes.find_by(post: post)&.destroy
    redirect_back fallback_location: root_path
  end

  def create_comment
    post = Post.find(params[:id])
    comment = post.comments.new(user: current_user, content: params[:comment][:content])
    if comment.save
      if post.user != current_user
        Notification.create!(
          user: post.user,
          actor: current_user,
          notifiable: comment,
          action: "comment"
        )
      end
      redirect_back fallback_location: root_path, notice: "Комментарий добавлен."
    else
      redirect_back fallback_location: root_path, alert: comment.errors.full_messages.to_sentence
    end
  end

  def chat_users
    user_ids = DirectMessage
      .where("sender_id = :id OR recipient_id = :id", id: current_user.id)
      .pluck(:sender_id, :recipient_id).flatten.uniq
      .reject { |id| id == current_user.id }

    users = User.where(id: user_ids).order(:name, :username).map do |u|
      { id: u.id, name: u.name.presence || u.username, username: u.username }
    end

    render json: users
  end

  def show_post
    @posts = Post.where(id: params[:id]).includes(:user, :likes, comments: :user)
  end

  def share_post
    post = Post.find_by(id: params[:post_id])
    unless post
      redirect_back fallback_location: root_path, alert: "Пост не найден."
      return
    end

    recipient = User.find_by(id: params[:recipient_id])
    unless recipient
      redirect_back fallback_location: root_path, alert: "Пользователь не найден."
      return
    end

    link = "#{request.base_url}/posts/#{post.id}"
    share_text = post.content.present? ? "#{post.content} — #{link}" : link
    current_user.sent_direct_messages.create!(recipient: recipient, content: share_text)
    post.increment!(:shares_count)
    redirect_to messages_path(user_id: recipient.id), notice: "Пост отправлен."
  end

  # Friendships

  def send_friend_request
    friend = User.find(params[:id])
    if current_user == friend
      redirect_back fallback_location: root_path, alert: "Нельзя отправить запрос самому себе."
      return
    end

    friendship = current_user.friendships.build(friend: friend, status: "pending")
    if friendship.save
      Notification.create!(
        user: friend,
        actor: current_user,
        notifiable: friendship,
        action: "friend_request"
      )
      redirect_back fallback_location: root_path, notice: "Запрос в друзья отправлен."
    else
      redirect_back fallback_location: root_path, alert: friendship.errors.full_messages.to_sentence
    end
  end

  def accept_friend_request
    friendship = current_user.inverse_friendships.find_by(user_id: params[:id], status: "pending")
    unless friendship
      redirect_back fallback_location: root_path, alert: "Запрос не найден."
      return
    end

    friendship.update!(status: "accepted")
    Notification.create!(
      user: friendship.user,
      actor: current_user,
      notifiable: friendship,
      action: "friend_accept"
    )
    redirect_back fallback_location: root_path, notice: "Запрос принят."
  end

  def reject_friend_request
    friendship = current_user.inverse_friendships.find_by(user_id: params[:id], status: "pending")
    unless friendship
      redirect_back fallback_location: root_path, alert: "Запрос не найден."
      return
    end

    friendship.destroy
    redirect_back fallback_location: root_path, notice: "Запрос отклонён."
  end

  # Notifications

  def notifications
    @notifications = current_user.notifications.recent.includes(:actor, :notifiable)
  end

  def mark_notifications_read
    current_user.notifications.unread.update_all(read_at: Time.current)
    head :ok
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

  def attach_profile_images(user)
    avatar = params.dig(:user, :avatar)
    cover_image = params.dig(:user, :cover_image)

    user.avatar.attach(avatar) if avatar.present?
    user.cover_image.attach(cover_image) if cover_image.present?
  end

  def mailer_configured?
    %w[SMTP_ADDRESS SMTP_PORT SMTP_DOMAIN SMTP_USERNAME SMTP_PASSWORD MAILER_FROM_EMAIL].all? do |key|
      EnvFile.fetch(key).present?
    end
  end

  def valid_password_change_code?(code)
    sent_code = session[:password_change_code].to_s
    sent_at = session[:password_change_code_sent_at].to_i

    sent_code.present? &&
      sent_code == code &&
      sent_at.positive? &&
      Time.at(sent_at) >= 15.minutes.ago
  end

  def clear_password_change_code!
    session.delete(:password_change_code)
    session.delete(:password_change_code_sent_at)
  end

  def build_chat_row(user)
    last_message = DirectMessage.between(current_user, user).last
    preview = if last_message
      if last_message.image.attached? && last_message.content.blank?
        "Изображение"
      elsif last_message.image.attached?
        "#{last_message.content}"
      else
        last_message.content
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
end


