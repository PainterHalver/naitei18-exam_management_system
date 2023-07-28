module Supervisor::QuestionsHelper
  def exclude_deleted_subject?
    params.dig(:q, :exclude_deleted_subject).present?
  end

  def filter_question_type_options
    Question.question_types.map do |t|
      [Question.human_attribute_name("question_type.#{t[0]}"), t[1]]
    end
  end

  def filter_subject_options
    Subject.select(:id, :name).map{|s| [s.name, s.id]}
  end

  def filter_supervisor_options
    User.supervisors.select(:id, :name).map{|u| [u.name, u.id]}
  end
end
