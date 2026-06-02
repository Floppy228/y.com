class AdminController < ApplicationController
  before_action :require_admin

  def index
    @query = params[:q].to_s.strip
    @users = User.order(:name, :username)
    if @query.present?
      @users = @users.where("LOWER(name) LIKE :q OR LOWER(username) LIKE :q OR LOWER(email) LIKE :q", q: "%#{@query.downcase}%")
    end
    @users = @users.limit(100)
  end

  def toggle_admin
    user = User.find(params[:id])
    if user == current_user
      redirect_to admin_path, alert: "Нельзя снять админа с самого себя."
      return
    end
    user.update(admin: !user.admin?)
    redirect_to admin_path(q: params[:q]), notice: "Права администратора #{user.admin? ? 'выданы' : 'сняты'} для #{user.name.presence || user.username}."
  end

  private

  def require_admin
    redirect_to root_path, alert: "Доступ запрещён." unless current_user&.admin?
  end
end
