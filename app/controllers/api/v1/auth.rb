require "jwt"

module API
  module V1
    class Auth < Grape::API
      include API::V1::Defaults

      resources :auth do
        desc "Login"
        params do
          requires :email
          requires :password
        end

        post "/login" do
          user = User.find_by email: params[:email]

          if user&.authenticate params[:password]
            error!("Account need to be activated", 401) unless user.activated?
            present jwt_token: JWT.encode({id: user.id, email: user.email,
                                           is_supervisor: user.is_supervisor,
                                           exp: Time.now.to_i + 4 * 3600},
                                          ENV["hmac_secret"], "HS256")
          else
            error!("Invalid email/pasword combination", 401)
          end
        end
      end
    end
  end
end
