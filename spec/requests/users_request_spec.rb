require 'rails_helper'
require 'shared_examples'
include SessionsHelper

RSpec.describe "Users", type: :request do
  describe "GET /new" do
    before do
      get "/signup"
    end
    it "create new empty user" do
      expect(assigns(:user)).to be_a_new(User)
    end

    it "render signup page" do
      expect(response).to render_template(:new)
    end
  end

  describe "POST /create" do
    let!(:user_params) {{name: "Bach",
      email: "example-bach@railstutorial.com",
      password: "foobar",
      password_confirmation: "foobar"}}
    context "success with valid attributes" do
      before do
        post "/signup", params: {user: user_params}
      end

      it "not activated when created" do
        expect(assigns(:user).activated).to be_falsey
      end

      it "not have activated time" do
        expect(assigns(:user).activated_at).to be_nil
      end

      it "create success" do
        expect(assigns(:user).name).to eq("Bach")
      end

      it "redirect to login path" do
        expect(response).to redirect_to(login_path)
      end

      it "inform user to wait for activation" do
        expect(flash[:info]).to eq(I18n.t("signup.wait_for_activation"))
      end
    end

    context "failed with invalid params" do
      before do
        post "/signup", params: {user: {name: "Bach",
                                        email: "example-bach",
                                        password: "foobar",
                                        password_confirmation: "fobar"}}
      end

      it "display error" do
        expect(flash[:danger]).to eq(I18n.t("signup.signup_failed"))
      end

      it "display signup page again" do
        expect(response).to render_template(:new)
      end
    end
  end
end

RSpec.describe UsersController, type: :controller do
  describe "GET /show" do
    context "show success" do
      let(:user) {create(:user)}
      before do
        create_list(:finished_test, 15, user: user)
        log_in user
        get :show, params: {id: user.id}
      end

      it "get all user's tests" do
        expect(assigns(:tests).length).to eq(15)
      end

      it "group subject and count" do
        expect(assigns(:subjects_data)).to eq(assigns(:tests).joins(:subject).group(:name).count)
      end
    end

    context "fail with not login" do
      let(:user) {create(:user)}
      before do
        get :show, params: {id: user.id}
      end

      it_behaves_like "not login error"

      it_behaves_like "back to login"
    end

    context "fail with id not found" do
      let(:user) {create(:user)}
      before do
        log_in user
        get :show, params: {id: -1}
      end

      it_behaves_like "user not found"

      it_behaves_like "back to login"
    end

    context "fail with unauthorization" do
      let(:user) {create(:user)}
      before do
        user_to_show = create(:user)
        log_in user
        get :show, params: {id: user_to_show.id}
      end

      it "inform unauthorization" do
        expect(flash[:danger]).to eq(I18n.t "users.profile.invalid")
      end

      it_behaves_like "back to home"
    end
  end

  describe "PATCH /update" do
    let(:user_params) {{name: "tester",
                        email: "example-tester@railstutorial.com",
                        password: "123456",
                        password_confirmation: "123456"}}
    context "update success" do
      let(:user) {create(:user)}
      before do
        log_in user
        patch :update, params: {user: user_params,
                                id: user.id}
        user.reload
      end

      it "update the user" do
        expect(user.email).to eq("example-tester@railstutorial.com")
      end

      it "inform success" do
        expect(flash[:success]).to eq(I18n.t "users.edit.saved")
      end

      it "redirect to subjects index page" do
        expect(response).to redirect_to user
      end
    end

    context "fail with invalid data" do
      let(:user) {create(:user)}
      let(:user_params) {{name: "tester",
                          email: "tester@gmail.com",
                          password: "123456",
                          password_confirmation: "12345"}}
      before do
        log_in user
        patch :update, params: {user: user_params,
                              id: user.id}
        user.reload
      end
      it "render edit page again" do
        expect(response).to render_template(:edit)
      end
    end

    context "fail with not login" do
      let(:user) {create(:user)}
      before do
        patch :update, params: {user: user_params,
                                id: user.id}
      end

      it_behaves_like "not login error"

      it_behaves_like "back to login"
    end

    context "fail with not correct user" do
      let(:user) {create(:user)}
      before do
        user_1 = User.create!(name: "tnt", email: "tnt@railstutorial.com",
                     password: "foobar", password_confirmation: "foobar")
        log_in user
        patch :update, params: {user: user_params,
                              id: user_1.id}
      end

      it "inform unauthorized" do
        expect(flash[:danger]).to eq(I18n.t "users.edit.user_invalid")
      end

      it_behaves_like "back to home"
    end

    context "fail with id not found" do
      let(:user) {create(:user)}
      before do
        log_in user
        patch :update, params: {user: user_params,
                              id: -1}
      end

      it_behaves_like "user not found"

      it_behaves_like "back to login"
    end
  end
end
