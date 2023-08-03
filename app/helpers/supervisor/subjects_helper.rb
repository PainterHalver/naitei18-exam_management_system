module Supervisor::SubjectsHelper
  def has_ongoing_test? subject
    subject.tests.progressing.present?
  end

  def has_no_question? subject
    subject.questions.with_deleted.empty?
  end
end
