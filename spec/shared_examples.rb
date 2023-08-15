RSpec.shared_examples "not login error" do
  it "show not login error" do
    expect(flash[:danger]).to eq(I18n.t "require_login")
  end
end

RSpec.shared_examples "back to login" do
  it "redirect to login page" do
    expect(response).to redirect_to login_path
  end
end

RSpec.shared_examples "back to home" do
  it "redirect to home page" do
    expect(response).to redirect_to root_path
  end
end

RSpec.shared_examples "user not found" do
  it "show not found user" do
    expect(flash[:danger]).to eq(I18n.t "user.error")
  end
end

RSpec.shared_examples "requires supervisor" do |method, action, params = {}|
  let!(:user) {create :user}
  let!(:supervisor) {create :supervisor}

  context "when user is not logged in" do
    it "redirects to login page" do
      send method, action, params: params
      expect(response).to redirect_to login_path
    end

    it "show not login error" do
      send method, action, params: params
      expect(flash[:danger]).to eq(I18n.t "require_login")
    end
  end

  context "when user is logged in" do
    before do
      log_in user
      send method, action, params: params
    end

    it "does not redirect to login page" do
      expect(response).not_to redirect_to login_path
    end

    it "does not show not login error" do
      expect(flash[:danger]).not_to eq(I18n.t "require_login")
    end
  end

  context "when user is not supervisor" do
    before do
      log_in user
      send method, action, params: params
    end

    it "redirects to home page" do
      expect(response).to redirect_to root_path
    end

    it "show no permission error" do
      expect(flash[:danger]).to eq(I18n.t "no_permission")
    end
  end

  context "when user is supervisor" do
    before do
      log_in supervisor
      send method, action, params: params
    end

    it "does not redirect to root_path" do
      expect(response).not_to redirect_to root_path
    end

    it "does not show no permission error" do
      expect(flash[:danger]).not_to eq(I18n.t "no_permission")
    end
  end
end

RSpec.shared_examples "back to users management page" do
  it "show user not supervisor" do
    expect(response).to redirect_to supervisor_users_path
  end
end

RSpec.shared_examples "invalid role for supervisor" do
  it "show user not supervisor" do
    expect(flash[:danger]).to eq(I18n.t "no_permission")
  end

  it_behaves_like "back to home"
end

RSpec.shared_examples "not found test" do
  it "inform test not found" do
    expect(flash[:danger]).to eq(I18n.t "tests.errors.not_found")
  end

  it_behaves_like "back to home"
end

RSpec.shared_examples "unauthorization for test" do
  it "inform unauthorized" do
    expect(flash[:danger]).to eq(I18n.t "tests.show.not_authorized")
  end

  it_behaves_like "back to home"
end

RSpec.shared_examples "handle not login error" do |method, action, params = {}|
  describe "execute a request without login" do
    before do
      send method, action, params: params
    end

    it_behaves_like "not login error"

    it_behaves_like "back to login"
  end
end

RSpec.shared_examples "handle unauthorization error" do |method, action, params = {}|
  describe "inform that user are not authorized" do
    let(:another_user) {create(:user)}
    let(:user) {create(:user)}
    before do
      test = create(:test, user: user)

      log_in another_user
      send method, action, params: {id: test.id}
    end

    it "inform unauthorized" do
      expect(flash[:danger]).to eq(I18n.t "tests.show.not_authorized")
    end
  end
end

RSpec.shared_examples "handle test completed error" do |method, action, params = {}|
  describe "inform that test has been completed" do
    before do
      user = create(:user)
      log_in user
      test = create(:finished_test, user: user)
      send method, action, params: {id: test.id}
    end

    it "inform the test was completed" do
      expect(flash[:danger]).to eq (I18n.t "tests.has_finished")
    end

    it_behaves_like "back to home"
  end
end

RSpec.shared_examples "status code 200" do
  it "returns status code 200" do
    expect(response).to have_http_status(200)
  end
end

RSpec.shared_examples "status code 201" do
  it "returns status code 201" do
    expect(response).to have_http_status(201)
  end
end

RSpec.shared_examples "status success" do
  it "returns status success" do
    expect(JSON.parse(response.body)["status"]).to eq("success")
  end
end

RSpec.shared_examples "status error" do
  it "returns status fail" do
    expect(JSON.parse(response.body)["status"]).to eq("error")
  end
end
