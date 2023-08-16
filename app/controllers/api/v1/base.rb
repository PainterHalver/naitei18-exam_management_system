require "grape-swagger"

module API
  module V1
    class Base < Grape::API
      mount API::V1::HealthCheck
      mount API::V1::Subjects
      mount API::V1::Tests
      mount API::V1::Questions
      mount API::V1::Auth
      mount API::V1::Users
      add_swagger_documentation(
        api_version: "v1",
        hide_documentation_path: true,
        mount_path: "/api/v1/swagger_doc"
      )
    end
  end
end
