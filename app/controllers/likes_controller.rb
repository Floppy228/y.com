class LikesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post

  def create
    @like = @post.likes.build(user: current_user)

    if @like.save
      redirect_back fallback_location: root_path, notice: "Пост лайкнут."
    else
      redirect_back fallback_location: root_path, alert: "Ты уже лайкнул этот пост."
    end
  end

  def destroy
    @like = @post.likes.find_by(user: current_user)

    if @like
      @like.destroy
      redirect_back fallback_location: root_path, notice: "Лайк убран."
    else
      redirect_back fallback_location: root_path, alert: "Лайк не найден."
    end
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end
end