class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post
  before_action :set_comment, only: :destroy

  def create
    @comment = @post.comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      redirect_back fallback_location: root_path, notice: "Комментарий добавлен."
    else
      redirect_back fallback_location: root_path, alert: @comment.errors.full_messages.to_sentence
    end
  end

  def destroy
    if @comment.user == current_user
      @comment.destroy
      redirect_back fallback_location: root_path, notice: "Комментарий удалён."
    else
      redirect_back fallback_location: root_path, alert: "Нельзя удалить чужой комментарий."
    end
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end

  def set_comment
    @comment = @post.comments.find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:content)
  end
end