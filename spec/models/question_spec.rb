require 'rails_helper'

RSpec.describe Question, type: :model do
  describe "#newest" do
    it "returns a ActiveRecord::Relation" do
      expect(Question.newest).to be_a_kind_of(ActiveRecord::Relation)
    end

    it "returns the correct order" do
      supervisor = FactoryBot.create(:supervisor)
      q1 = build(:question, creator: supervisor)
      q1.save(validate: false)
      q2 = build(:question, creator: supervisor)
      q2.save(validate: false)
      expect(Question.newest).to eq([q2, q1])
    end
  end

  describe ".ransackable_attributes" do
    it 'returns the correct array of attributes' do
      expected_attributes = %w(content question_type created_at subject_id)
      expect(Question.ransackable_attributes).to eq(expected_attributes)
    end
  end

  describe ".ransackable_associations" do
    it 'returns the correct array of associations' do
      expected_associations = %w(creator)
      expect(Question.ransackable_associations).to eq(expected_associations)
    end
  end

  describe ".ransackable_scopes" do
    it 'returns the correct array of scopes' do
      expected_scopes = %i(exclude_deleted_subject)
      expect(Question.ransackable_scopes).to eq(expected_scopes)
    end
  end

  describe "#must_have_one_correct_answer" do
    context "when correct answers count is valid" do
      it "has no error" do
        question = build(:question)
        question.answers = [build(:correct_answer)]
        question.send(:must_have_one_correct_answer)
        expect(question.errors[:base]).to be_empty
      end
    end

    context "when correct answers count is invalid" do
      it "has error" do
        question = build(:question)
        question.answers = [build(:incorrect_answer)]
        question.send(:must_have_one_correct_answer)
        expect(question.errors[:base]).to include(I18n.t("errors.must_have_one_correct_answer"))
      end
    end
  end

  describe "#validate_single_type" do
    context "when single choice question has more than 1 correct answer" do
      it "has error" do
        question = build(:question, question_type: :single_choice)
        question.answers = [build(:correct_answer), build(:correct_answer)]
        question.send(:validate_single_type)
        expect(question.errors[:base]).to include(I18n.t("errors.must_have_exactly_one_correct_answer"))
      end
    end

    context "when single choice question has 1 correct answer" do
      it "has no error" do
        question = build(:question, question_type: :single_choice)
        question.answers = [build(:correct_answer)]
        question.send(:validate_single_type)
        expect(question.errors[:base]).to be_empty
      end
    end
  end

  describe "#validate_multiple_type" do
    context "when multiple choice question has less than 2 correct answers" do
      it "has error" do
        question = build(:question, question_type: :multiple_choice)
        question.answers = [build(:correct_answer)]
        question.send(:validate_multiple_type)
        expect(question.errors[:base]).to include(I18n.t("errors.must_have_at_least_two_correct_answers"))
      end
    end

    context "when multiple choice question has more than 1 correct answer" do
      it "has no error" do
        question = build(:question, question_type: :multiple_choice)
        question.answers = [build(:correct_answer), build(:correct_answer)]
        question.send(:validate_multiple_type)
        expect(question.errors[:base]).to be_empty
      end
    end
  end
end
