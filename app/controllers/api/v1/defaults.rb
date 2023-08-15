module API
  module V1
    module Defaults
      extend ActiveSupport::Concern

      included do
        prefix "api"
        version "v1", using: :path
        default_format :json
        format :json

        rescue_from ActiveRecord::RecordNotFound do |e|
          raise e if Rails.env.development?

          error_response(message: e.message, status: 404)
        end

        rescue_from ActiveRecord::StatementInvalid do |e|
          raise e if Rails.env.development?

          error_response(message: "Invalid parameters", status: 400)
        end

        rescue_from Grape::Exceptions::ValidationErrors do |e|
          raise e if Rails.env.development?

          error_response(message: e.message, status: 400)
        end

        rescue_from :all do |e|
          raise e if Rails.env.development?

          error_response(message: "Internal server error", status: 500)
        end
      end
    end
  end
end
