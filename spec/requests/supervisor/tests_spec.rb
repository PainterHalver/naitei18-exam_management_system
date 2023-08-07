require "rails_helper"
require "shared_examples"
include SessionsHelper

RSpec.describe Supervisor::TestsController, type: :controller do
  describe "GET index" do
    include_examples "requires supervisor", :get, :index, {user_id: 1}
    let!(:user) {create :user}
    let!(:supervisor) {create :supervisor}
    let!(:test) {create :finished_test, user: user}

    context "when user not exist" do
      before do
        log_in supervisor
        get :index, params: {user_id: 0}
      end

      it "show user not exist error" do
        expect(flash[:danger]).to eq(I18n.t "user.error")
      end
    end

    context "when user exist" do
      it "should have all tests if total <= #{Settings.pagination.per_page_10}" do
        log_in supervisor
        get :index, params: {user_id: user.id}
        expect(assigns[:tests].length).to eq(user.tests.size)
      end

      it "should have #{Settings.pagination.per_page_10} tests if total > #{Settings.pagination.per_page_10}" do
        create_list(:finished_test, Settings.pagination.per_page_10, user: user)
        log_in supervisor
        get :index, params: {user_id: user.id}
        expect(assigns[:tests].length).to eq(Settings.pagination.per_page_10)
      end
    end
  end
end
