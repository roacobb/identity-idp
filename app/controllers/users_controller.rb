class UsersController < ApplicationController
  def destroy
    path_after_cancellation = decorated_session.cancel_link_path
    destroy_user
    flash[:success] = t('sign_up.cancel.success')
    redirect_to path_after_cancellation
  end

  private

  def destroy_user
    user = current_user || User.find_by(confirmation_token: session[:user_confirmation_token])
    user && user.destroy!
    sign_out if user
  end
end
