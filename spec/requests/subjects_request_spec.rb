require "rails_helper"

RSpec.describe "Subjects", type: :request do

  let!(:subject) { FactoryBot.create(:subject) }
  let!(:subject_1) { FactoryBot.create(:subject) }

  describe "GET index" do
    it "returns http success" do
      get "/subjects"
      expect(response).to have_http_status(:success)
    end

    it "should have all subjects if total <= 10" do
      get "/subjects"
      expect(assigns[:subjects].length).to eq(2)
    end

    it "should have 10 subjects if total > 10" do
      FactoryBot.create_list(:subject, 10)
      get "/subjects"
      expect(assigns[:subjects].length).to eq(10)
    end
  end

  describe "GET show" do
    context "when subject found" do
      before do
        get "/subjects/#{subject.id}"
      end

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "assign @subject" do
        expect(assigns[:subject]).to be_an_instance_of(Subject)
      end

      it "assign @test" do
        expect(assigns[:test]).to be_a_new(Test)
      end
    end

    context "when subject not found" do
      before do
        get "/subjects/NON_EXISTENT"
      end

      it "should show correct danger flash" do
        expect(flash[:danger]).to eq(I18n.t("subjects.show.not_found"))
      end

      it "should redirect to subjects_path" do
        expect(response).to redirect_to(subjects_path)
      end
    end
  end

end
