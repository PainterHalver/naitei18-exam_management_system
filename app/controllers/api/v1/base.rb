require "grape-swagger"

module API
  module V1
    class Base < Grape::API
      formatter :json, API::Formatters::SuccessFormatter
      error_formatter :json, API::Formatters::ErrorFormatter
      mount API::V1::HealthCheck
      mount API::V1::Subjects
      mount API::V1::Tests
      mount API::V1::Questions
      mount API::V1::Auth
      mount API::V1::Users
    end
  end
end
