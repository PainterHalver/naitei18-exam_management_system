module API
  module V1
    class Tests < Grape::API
      include API::V1::Defaults
      include API::V1::Helpers::TestHelper
      include API::V1::Helpers::AnswerSubmitHelper

      before do
        validate_authentication
      end

      helpers do
        def update_test_empty
          return if @test.update({score: 0, status: :failed,
                                  end_time: Time.zone.now})

          error!("Internal server error", 500)
        end

        def validation_for_submit
          load_test
          require_authorization_with_test_modification
          require_doing_test
        end

        def pre_process
          post_data_handle
          true_answers
        end

        def load_test
          @test = Test.includes(test_questions: [:answers, :question])
                      .find_by id: params[:id]
          return if @test

          error!("test not found", 404)
        end

        def require_authorization_with_test_modification
          return if @current_user.id == @test.user_id &&
                    @current_user.activated?

          error!("can not access this test", :forbidden)
        end
      end

      resource :tests do
        desc "Return a test result"
        params do
          requires :id, type: String, desc: "ID of the test"
        end
        route_param :id do
          get do
            load_test
            if @current_user.id == @test.user_id ||
               (@current_user.is_supervisor? && !@test.doing?)
              present @test, with: API::Entities::Test
            else
              error!("can not access this test", :forbidden)
            end
          end
        end
      end

      resource :tests do
        desc "create a test"
        params do
          requires :subject_id, desc: "The id of subject the test belongs to"
        end
        post do
          if @current_user.is_supervisor?
            error!("Must be a normal user", :forbidden)
          end

          subject = Subject.includes(:questions).find_by id: params[:subject_id]
          inform_error_for_test_create subject
          @test = subject.tests.build({user_id: @current_user.id,
                                       start_time: Time.zone.now})
          ActiveRecord::Base.transaction do
            @test.save!
            add_questions_to_test @test, subject
          end

          enqueue_job
          present @test, with: API::Entities::Test
        rescue ActiveRecord::Rollback
          error!("Internal server error", 500)
        end
      end

      resource :tests do
        desc "submit or save a test"
        params do
          requires :id, desc: "The id of test"
        end
        route_param :id do
          before do
            validation_for_submit
          end
          patch do
            corrected = []
            detail_answers = []
            pre_process
            save_answers detail_answers
            if Settings.update_commit.include?(params[:commit])
              if detail_answers.empty?
                update_test_empty
              else
                submit_test corrected
              end
            end
            present @test, with: API::Entities::Test
          rescue ActiveRecord::Rollback
            error!("Internal server error", 500)
          end
        end
      end
    end
  end
end
