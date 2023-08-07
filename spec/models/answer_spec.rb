require 'rails_helper'

RSpec.describe Answer, type: :model do
  describe "#set_disabled" do
    it "should returns true" do
      answer = FactoryBot.build(:answer)
      expect(answer.set_disabled).to eq(true)
    end
  end
end
