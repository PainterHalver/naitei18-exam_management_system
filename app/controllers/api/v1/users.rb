require "jwt"

module API
  module V1
    class Users < Grape::API
      include API::V1::Defaults
      include API::V1::Helpers::PaginationHelper

      before do
        validate_authentication
      end

      resources :users do
        desc "Edit profile"
        params do
          optional :name
          optional :email
          optional :password
          optional :password_confirmation
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

      resources :users do
        desc "Show tests history"
        params do
          use :pagination
          requires :id, desc: "The ID of user"
        end
        route_param :id do
          get "tests" do
            user = User.find_by id: params[:id]
            error!("User not found", 404) unless user

            tests = Test.where(user_id: params[:id]).newest
            tests = paginate tests

            if @current_user.id == user.id || @current_user.is_supervisor?
              present tests
            else
              error!("You can not access history", :forbidden)
            end
          end
        end
      end
    end
  end
end
