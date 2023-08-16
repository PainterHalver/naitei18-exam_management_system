module API
  class Base < Grape::API
    mount API::V1::Base
    add_swagger_documentation(
      api_version: "v1",
      hide_documentation_path: true,
      mount_path: "/api/v1/swagger_doc",
      schemes: %w(http https),
      security_definitions: {
        Bearer: {
          type: "apiKey",
          name: "Authorization",
          in: "header"
        }
      },
      security: [Bearer: []]
    )
  end
end
