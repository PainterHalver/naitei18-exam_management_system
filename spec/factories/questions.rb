FactoryBot.define do
  factory :question do
    creator {FactoryBot.create(:supervisor)}
    subject
    content {Faker::Lorem.sentence(word_count: 20)}
    question_type {Question.question_types.values.sample}
  end
end
