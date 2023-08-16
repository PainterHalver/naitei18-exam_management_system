module API
  module V1
    class Tests < Grape::API
      include API::V1::Defaults

      before do
        validate_authentication
      end

      resource :tests do
        desc "Return a test result"
        params do
          requires :id, type: String, desc: "ID of the test"
        end
        route_param :id do
          get do
            test = Test.includes(test_questions: [:answers, :question])
                       .find_by(id: params[:id])

            error!("Test not found", 404) if test.nil?

            unless test.failed? || test.passed?
              error!("You can see completed test only", :forbidden)
            end

            if @current_user.id == test.user_id || @current_user.is_supervisor?
              present test, with: API::Entities::Test
            else
              error!("You can not access this test", :forbidden)
            end
          end
        end
      end
    end
  end
end
