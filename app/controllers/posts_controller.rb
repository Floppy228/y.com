class PostsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post, only: :destroy

  def create
    Rails.logger.debug "POST PARAMS: #{params.inspect}"
    @post = current_user.posts.build(post_params)

    if @post.save
      redirect_back fallback_location: root_path, notice: "Пост опубликован."
    else
      redirect_back fallback_location: root_path, alert: @post.errors.full_messages.to_sentence
    end
  end

  def destroy
    if @post.user == current_user
      @post.destroy
      redirect_back fallback_location: root_path, notice: "Пост удалён."
    else
      redirect_back fallback_location: root_path, alert: "Нельзя удалить чужой пост."
    end
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:content)
  end
end