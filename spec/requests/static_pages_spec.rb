require 'rails_helper'

RSpec.describe "StaticPages", type: :request do
  describe "GET home" do
    context "when user not logged in" do
      before do
        get root_path
      end

      it "should redirect to signup_path" do
        expect(response).to redirect_to signup_path
      end

      it "should have correct info flash message" do
        expect(flash[:info]).to eq(I18n.t("static_pages.home.login_message"))
      end
    end

    context "when normal user logged in" do
      let!(:user) { FactoryBot.create(:user) }

      before do
        post login_path, params: { session: { email: user.email,
                                              password: user.password } }
        get root_path
      end

      it "should return http success" do
        expect(response).to have_http_status(:success)
      end

      it "should render correct template" do
        expect(response).to render_template :home
      end

      it "should have all tests if total <= #{Settings.pagination.per_page_10}" do
        expect(assigns[:tests].length).to eq(Test.all.size)
      end

      it "should have #{Settings.pagination.per_page_10} tests if total > #{Settings.pagination.per_page_10}" do
        FactoryBot.create_list(:finished_test, Settings.pagination.per_page_10 + 5, user: user)
        get root_path
        expect(assigns[:tests].length).to eq(Settings.pagination.per_page_10)
      end
    end

    context "when supervisor logged in" do
      let!(:supervisor) { FactoryBot.create(:supervisor) }

      before do
        post login_path, params: { session: { email: supervisor.email,
                                              password: supervisor.password } }
        get root_path
      end

      it "should redirect to supervisor_root_path" do
        expect(response).to redirect_to supervisor_root_path
      end
    end
  end
end
