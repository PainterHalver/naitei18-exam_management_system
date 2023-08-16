require "jwt"

module API
  module V1
    class Users < Grape::API
      include API::V1::Defaults
      include API::V1::Helpers::PaginationHelper

      before do
        validate_authentication
      end

      helpers do
        def load_user_by_id user_id
          user = User.find_by id: user_id
          return user unless user.nil?

          error!("User not found", 404)
        end

        def error_inform_for_account_management user, action
          if user.id == @current_user.id
            error!("can not #{action} your self", :forbidden)
          end
          if user.activated? && action == "activate"
            error!("can not activate an active user", :forbidden)
          end
          if !user.activated? && action == "deactivate"
            error!("can not deactivate an inactive user", :forbidden)
          end
          return unless user.is_supervisor?

          error!("can not #{action} a supervisor", :forbidden)
        end
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
            user = load_user_by_id params[:id]

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

      resources :users do
        before do
          require_supervisor
        end
        desc "activate user"
        params do
          requires :id, desc: "the ID of user"
        end
        route_param :id do
          patch "activate" do
            user = load_user_by_id params[:id]
            error_inform_for_account_management(user, "activate")

            if user.update(activated: true, activated_at: Time.zone.now)
              present(user: user, message: "account activated")
            else
              error!(@current_user.errors.full_messages, 422)
            end
          end
        end
      end

      resources :users do
        before do
          require_supervisor
        end
        desc "deactivate user"
        params do
          requires :id, desc: "the ID of user"
        end
        route_param :id do
          patch "deactivate" do
            user = load_user_by_id params[:id]
            error_inform_for_account_management(user, "deactivate")

            if user.update(activated: false)
              present(user: user, message: "account deactivated")
            else
              error!(@current_user.errors.full_messages, 422)
            end
          end
        end
      end
    end
  end
end
