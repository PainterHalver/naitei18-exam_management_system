class QuestionsExporter
  attr_reader :questions

  def initialize questions
    @questions = questions
  end

  def call
    p = Axlsx::Package.new
    wb = p.workbook
    wb.add_worksheet(name: "Questions") do |sheet|
      header_row = ["Content", "Question type"]
      max_answers_count = @questions.map{|q| q.answers.size}.max
      (1..max_answers_count).each do |index|
        header_row << "Answer #{index}"
        header_row << "Is correct #{index}"
      end
      sheet.add_row header_row

      add_questions_to_sheet sheet
    end
    p
  end

  private

  def add_questions_to_sheet sheet
    @questions.each do |question|
      row = [question.content, question.question_type]
      question.answers.each do |answer|
        row << answer.content
        row << answer.is_correct
      end
      sheet.add_row row
    end
  end
end
