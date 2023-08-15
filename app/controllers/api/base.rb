module API
  class Base < Grape::API
    formatter :json, API::Formatters::SuccessFormatter
    error_formatter :json, API::Formatters::ErrorFormatter

    mount API::V1::Base
  end
end
