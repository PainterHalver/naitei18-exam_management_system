require "jwt"

module API
  module V1
    module Defaults
      extend ActiveSupport::Concern

      included do
        prefix "api"
        version "v1", using: :path
        default_format :json
        format :json

        include API::V1::RescueFrom

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
      end
    end

    module RescueFrom
      extend ActiveSupport::Concern
      included do
        rescue_from ActiveRecord::RecordNotFound do |e|
          raise e if Rails.env.development?

          error!("No records found", 404)
        end

        rescue_from ActiveRecord::StatementInvalid,
                    Grape::Exceptions::ValidationErrors do |e|
          raise e if Rails.env.development?

          error!("One or more parameters are invalid", 400)
        end

        rescue_from :all do |e|
          raise e if Rails.env.development?

          error!("Internal server error", 500)
        end
      end
    end
  end
end
