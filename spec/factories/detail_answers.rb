FactoryBot.define do
  factory :detail_answer, class: DetailAnswer do
    test_question
    answer
  end
end
