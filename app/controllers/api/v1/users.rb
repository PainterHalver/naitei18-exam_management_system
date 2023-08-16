require "jwt"

module API
  module V1
    class Users < Grape::API
      include API::V1::Defaults

      resources :users do
        desc "Edit profile"
        params do
          optional :name
          optional :email
          optional :password
          optional :password_confirmation
        end

        before do
          validate_authentication
        end

        patch do
          if params[:password].present? && params[:password_confirmation].nil?
            error!("Must confirm your password", 422)
          end

          if @current_user.update(declared(params, include_missing: false))
            present({user: @current_user, message: "update success"})
          else
            error!(@current_user.errors.full_messages, 422)
          end
        end
      end
    end
  end
end
