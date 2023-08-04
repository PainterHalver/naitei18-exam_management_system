require "rails_helper"

RSpec.describe Subject, type: :model do
  describe "#newest" do
    it "returns a ActiveRecord::Relation" do
      expect(Subject.newest).to be_a_kind_of(ActiveRecord::Relation)
    end

    it "returns the correct order" do
      s1 = FactoryBot.create(:subject)
      s2 = FactoryBot.create(:subject)
      expect(Subject.newest).to eq([s2, s1])
    end
  end

  describe '.ransackable_associations' do
    it 'returns the correct array of associations' do
      expected_associations = %w(image_attachment image_blob questions tests user)
      expect(Subject.ransackable_associations).to eq(expected_associations)
    end
  end

  describe '.ransackable_attributes' do
    it 'returns the correct array of attributes' do
      expected_attributes = %w(created_at deleted_at description id name
        pass_score question_amount test_duration updated_at user_id)
      expect(Subject.ransackable_attributes).to eq(expected_attributes)
    end
  end
end
