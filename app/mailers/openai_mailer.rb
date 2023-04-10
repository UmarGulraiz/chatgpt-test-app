class OpenaiMailer < ApplicationMailer
  default from: "umar.gulraiz1@gmail.com"

  def send_response(
    year_level,
    type_of_paragraph,
    essay_type,
    essay_question,
    your_paragraph,
    suggestion_array,
    email_address
  )
    @year_level = year_level
    @type_of_paragraph = type_of_paragraph
    @essay_type = essay_type
    @essay_question = essay_question
    @your_paragraph = your_paragraph
    @suggestions = suggestion_array
    mail(to: email_address, subject: "Essay suggestions")
  end
end
