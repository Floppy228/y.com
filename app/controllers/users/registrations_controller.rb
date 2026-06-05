class Users::RegistrationsController < Devise::RegistrationsController
  def create
    unless params[:terms_check] == "1"
      return redirect_to auth_path(auth_mode: "register"), alert: "Примите условия использования"
    end

    build_resource(sign_up_params)
    resource.save

    if resource.persisted?
      set_flash_message!(:notice, :signed_up)
      sign_up(resource_name, resource)
      redirect_to after_sign_up_path_for(resource)
    else
      message = resource.errors.full_messages.to_sentence
      redirect_to auth_path(auth_mode: "register"), alert: message
    end
  end
end
