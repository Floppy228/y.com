require Rails.root.join("config/env_file").to_s

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

    @search_users = if @query.present?
      users_scope
        .where("LOWER(name) LIKE :q OR LOWER(username) LIKE :q OR LOWER(email) LIKE :q", q: "%#{@query.downcase}%")
        .order(:name, :username)
    else
      User.none
    end

    @direct_messages = if @selected_user
      DirectMessage.between(current_user, @selected_user)
    else
      DirectMessage.none
    end
  end

  def ai
    @ai_messages = current_user.ai_messages.order(:created_at)
  end

  def ai_ask
    prompt = params[:prompt].to_s.strip
    if prompt.blank?
      redirect_to ai_path, alert: "Enter a question for Y-Core."
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
    redirect_to ai_path, notice: "Y-Core chat was cleared."
  end

  def clear_messages_chat
    selected_user = User.where.not(id: current_user.id).find_by(id: params[:user_id])
    unless selected_user
      redirect_to messages_path, alert: "Select a chat first."
      return
    end

    DirectMessage.between(current_user, selected_user).delete_all
    redirect_to messages_path(user_id: selected_user.id), notice: "Chat was cleared."
  end

  def following
  end

  def create_message
    recipient = User.where.not(id: current_user.id).find_by(id: params[:recipient_id])
    content = params[:content].to_s.strip

    unless recipient
      redirect_to messages_path, alert: "Select a user to start chat."
      return
    end

    if content.blank?
      redirect_to messages_path(user_id: recipient.id), alert: "Enter a message."
      return
    end

    current_user.sent_direct_messages.create!(recipient: recipient, content: content)
    redirect_to messages_path(user_id: recipient.id), notice: "Message sent."
  rescue StandardError
    redirect_to messages_path(user_id: recipient&.id), alert: "Failed to send message."
  end

  def update_message
    message = current_user.sent_direct_messages.find_by(id: params[:id])
    unless message
      redirect_to messages_path, alert: "Message not found."
      return
    end
    content = params[:content].to_s.strip
    if content.blank?
      redirect_to messages_path(user_id: direct_message_partner(message).id), alert: "Message text cannot be empty."
      return
    end
    if message.update(content: content)
      redirect_to messages_path(user_id: direct_message_partner(message).id), notice: "Message updated."
    else
      redirect_to messages_path(user_id: direct_message_partner(message).id), alert: message.errors.full_messages.to_sentence
    end
  end
  def destroy_message
    message = current_user.sent_direct_messages.find_by(id: params[:id])
    unless message
      redirect_to messages_path, alert: "Message not found."
      return
    end
    chat_user = direct_message_partner(message)
    message.destroy
    redirect_to messages_path(user_id: chat_user.id), notice: "Message deleted."
  end

  def settings
    @user = current_user
  end

  def password_reset
    @user = current_user
  end

  def send_password_change_code
    unless mailer_configured?
      redirect_to settings_password_reset_path, alert: "Email is not configured. Fill SMTP fields in .env."
      return
    end

    code = format("%06d", rand(0..999_999))
    session[:password_change_code] = code
    session[:password_change_code_sent_at] = Time.current.to_i

    PasswordCodeMailer.change_password_code(current_user, code).deliver_now
    redirect_to settings_password_reset_path, notice: "Code sent to #{current_user.email}."
  rescue StandardError
    redirect_to settings_password_reset_path, alert: "Failed to send email. Check SMTP settings in .env."
  end

  def update_password_from_settings
    code = params[:code].to_s.strip
    password = params[:password].to_s
    password_confirmation = params[:password_confirmation].to_s

    if code.blank? || password.blank? || password_confirmation.blank?
      redirect_to settings_password_reset_path, alert: "Fill in code and both password fields."
      return
    end

    unless valid_password_change_code?(code)
      redirect_to settings_password_reset_path, alert: "Code is invalid or expired."
      return
    end

    if current_user.update(password: password, password_confirmation: password_confirmation)
      clear_password_change_code!
      bypass_sign_in current_user
      redirect_to settings_password_reset_path, notice: "Password was changed."
    else
      redirect_to settings_password_reset_path, alert: current_user.errors.full_messages.to_sentence
    end
  end

  def update_settings_account
    @user = current_user

    if @user.update(filtered_user_params(:username, :email))
      redirect_to settings_path, notice: "Account settings saved."
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :settings, status: :unprocessable_entity
    end
  end

  def update_settings_profile
    @user = current_user

    if @user.update(filtered_user_params(:name, :bio, :status, :birthday))
      attach_profile_images(@user)
      redirect_to settings_path, notice: "Profile saved."
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :settings, status: :unprocessable_entity
    end
  end

  def update_settings_chats
    @user = current_user

    if @user.update(filtered_user_params(:message_send_shortcut))
      redirect_to settings_path, notice: "Chat settings saved."
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :settings, status: :unprocessable_entity
    end
  end

  def create_post
    post = current_user.posts.new(content: params[:post][:content])

    if post.save
      redirect_to root_path, notice: "Post published."
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

    {
      user: user,
      preview: last_message&.content.presence || "Р§Р°С‚ РµС‰Рµ РЅРµ РЅР°С‡Р°С‚",
      time: last_message&.created_at,
      active: @selected_user&.id == user.id
    }
  end

  def direct_message_partner(message)
    message.sender_id == current_user.id ? message.recipient : message.sender
  end
end


