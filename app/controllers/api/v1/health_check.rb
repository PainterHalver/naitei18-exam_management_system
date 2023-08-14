module API
  module V1
    class HealthCheck < Grape::API
      include API::V1::Defaults

      resource :health_check do
        desc "Check server status"
        get "", root: :health_check do
          {status: "ok"}
        end
      end
    end
  end
end
