class ApplicationController < ActionController::Base
  def authenticate_user!
    redirect_to auth_path unless user_signed_in?
  end
  before_action :authenticate_user!
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
end
