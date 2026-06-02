class AdminController < ApplicationController
  before_action :require_admin

  def index
    @tab = params[:tab].presence_in(%w[users posts]) || "dashboard"

    case @tab
    when "users"
      @query = params[:q].to_s.strip
      @users = User.order(:name, :username)
      if @query.present?
        @users = @users.where("LOWER(name) LIKE :q OR LOWER(username) LIKE :q OR LOWER(email) LIKE :q", q: "%#{@query.downcase}%")
      end
      @users = @users.limit(100)
    when "posts"
      @query = params[:q].to_s.strip
      @posts = Post.includes(:user).order(created_at: :desc)
      if @query.present?
        @posts = @posts.where("LOWER(content) LIKE :q", q: "%#{@query.downcase}%")
      end
      @posts = @posts.limit(50)
    else
      @stats = {
        users: User.count,
        posts: Post.count,
        comments: Comment.count,
        likes: Like.count,
        messages: DirectMessage.count,
        shares: Post.sum(:shares_count)
      }
    end
  end

  def toggle_admin
    user = User.find(params[:id])
    if user == current_user
      redirect_to admin_path(tab: "users", q: params[:q]), alert: "Нельзя снять админа с самого себя."
      return
    end
    user.update(admin: !user.admin?)
    redirect_to admin_path(tab: "users", q: params[:q]), notice: "Права администратора #{user.admin? ? 'выданы' : 'сняты'} для #{user.name.presence || user.username}."
  end

  def ban
    user = User.find(params[:id])
    if user == current_user
      redirect_to admin_path(tab: "users", q: params[:q]), alert: "Нельзя забанить самого себя."
      return
    end
    user.update(banned: true, ban_reason: params[:ban_reason].to_s.strip)
    redirect_to admin_path(tab: "users", q: params[:q]), notice: "Пользователь #{user.username} забанен."
  end

  def unban
    user = User.find(params[:id])
    user.update(banned: false, ban_reason: nil)
    redirect_to admin_path(tab: "users", q: params[:q]), notice: "Пользователь #{user.username} разбанен."
  end

  def destroy_user
    user = User.find(params[:id])
    if user == current_user
      redirect_to admin_path(tab: "users"), alert: "Нельзя удалить самого себя."
      return
    end
    user.destroy
    redirect_to admin_path(tab: "users"), notice: "Пользователь #{user.username} удалён."
  end

  def destroy_post
    post = Post.find(params[:id])
    post.destroy
    redirect_to admin_path(tab: "posts", q: params[:q]), notice: "Пост удалён."
  end

  private

  def require_admin
    redirect_to root_path, alert: "Доступ запрещён." unless current_user&.admin?
  end
end
