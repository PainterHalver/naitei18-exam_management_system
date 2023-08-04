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
