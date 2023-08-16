module API
  module V1
    module Defaults
      extend ActiveSupport::Concern

      included do
        prefix "api"
        version "v1", using: :path
        default_format :json
        format :json

        helpers do
          def validate_authentication
            token = request.headers["Authorization"]&.split(" ")&.[](1)
            if token
              user_id = JWT.decode(token, ENV["hmac_secret"],
                                   true,
                                   {algorithm: "HS256"})[0]["id"]
              @current_user = User.find_by id: user_id
            end
            error!("You need to log in", 401) unless @current_user
          rescue JWT::ExpiredSignature
            error!("Your session has ended", 401)
          end

          def require_supervisor
            return if @current_user.is_supervisor

            error!("You are not authorized to do this", :forbidden)
          end
        end

        rescue_from ActiveRecord::RecordNotFound do |e|
          raise e if Rails.env.development?

          error!(message: e.message, status: 404)
        end

        rescue_from ActiveRecord::StatementInvalid do |e|
          raise e if Rails.env.development?

          error!(message: "Invalid parameters", status: 400)
        end

        rescue_from Grape::Exceptions::ValidationErrors do |e|
          raise e if Rails.env.development?

          error!(message: e.message, status: 400)
        end

        rescue_from :all do |e|
          raise e if Rails.env.development?

          error!(message: "Internal server error", status: 500)
        end
      end
    end
  end
end
