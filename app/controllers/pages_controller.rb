class PagesController < ApplicationController
  skip_before_action :require_login, only: [:auth, :send_password_reset_instructions]
  before_action :redirect_authenticated_user_from_auth, only: [:auth]

  def index
    @query = params[:q].to_s.strip
    @posts = Post.includes(:user, :likes, comments: :user)
    if user_signed_in?
      excluded = excluded_user_ids
      @posts = @posts.where.not(user_id: excluded)
    end
    if @query.present?
      @posts = @posts.where("LOWER(content) LIKE :q", q: "%#{@query.downcase}%")
    end
    @posts = @posts.order(created_at: :desc)
  end

  def auth
    @auth_mode = normalized_auth_mode
  end

  def profile
    @user = current_user
    @banned_user = @user.banned?
    @posts = current_user.posts.includes(:likes, comments: :user).order(created_at: :desc)
  end

  def user_profile
    @user = User.find(params[:id])
    @banned_user = @user.banned?
    @blocked_by_them = current_user.blocked_by?(@user)
    unless @blocked_by_them
      @posts = @user.posts.includes(:likes, comments: :user).order(created_at: :desc)
    else
      @posts = Post.none
    end
    render :profile
  end

  def following
    @query = params[:q].to_s.strip
    @age_from = params[:age_from].to_s.strip.presence
    @age_to = params[:age_to].to_s.strip.presence
    @searching = @query.present? || @age_from.present? || @age_to.present?

    if @searching
      @users = User.where.not(id: current_user.id)
      @users = @users.where.not(id: excluded_user_ids)
      if @query.present?
        @users = @users.where("LOWER(name) LIKE :q OR LOWER(username) LIKE :q", q: "%#{@query.downcase}%")
      end
      if @age_from.present?
        @users = @users.where("birthday <= ?", Date.today - @age_from.to_i.years)
      end
      if @age_to.present?
        @users = @users.where("birthday >= ?", Date.today - (@age_to.to_i + 1).years + 1.day)
      end
      @users = @users.order(:name, :username)
    else
      friend_ids = current_user.friendships.where(status: "accepted").pluck(:friend_id) +
                   current_user.inverse_friendships.where(status: "accepted").pluck(:user_id)
      @users = User.where(id: friend_ids).where.not(id: excluded_user_ids).order(:name, :username)
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
        create_notification(user: post.user, actor: current_user, notifiable: post, action: "like")
      end
    end
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("post_#{post.id}", partial: "posts/post", locals: { post: post.reload }) }
      format.html { redirect_back fallback_location: root_path }
    end
  end

  def unlike_post
    post = Post.find(params[:id])
    current_user.likes.find_by(post: post)&.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("post_#{post.id}", partial: "posts/post", locals: { post: post.reload }) }
      format.html { redirect_back fallback_location: root_path }
    end
  end

  def create_comment
    post = Post.find(params[:id])
    comment = post.comments.new(user: current_user, content: params[:comment][:content])
    if comment.save
      if post.user != current_user
        create_notification(user: post.user, actor: current_user, notifiable: comment, action: "comment")
      end
      redirect_back fallback_location: root_path, notice: "Комментарий добавлен."
    else
      redirect_back fallback_location: root_path, alert: comment.errors.full_messages.to_sentence
    end
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

    if current_user.blocked?(recipient) || current_user.blocked_by?(recipient)
      redirect_back fallback_location: root_path, alert: "Невозможно отправить пост этому пользователю."
      return
    end

    link = "#{request.base_url}/posts/#{post.id}"
    share_text = post.content.present? ? "#{post.content} — #{link}" : link
    current_user.sent_direct_messages.create!(recipient: recipient, content: share_text)
    broadcast_unread_badge(recipient)
    post.increment!(:shares_count)
    redirect_to messages_path(user_id: recipient.id), notice: "Пост отправлен."
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

  def terms
  end
end
