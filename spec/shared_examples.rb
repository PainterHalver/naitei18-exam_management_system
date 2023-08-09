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
