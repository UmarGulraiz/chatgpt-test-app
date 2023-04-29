class OpenaiMailer < ApplicationMailer
  default from: "umar.gulraiz1@gmail.com"

  def send_response(type_of_paragraph, essay_type, email_address, essay_suggester_id)
    @essay_suggester = EssaySuggester.find(essay_suggester_id)
    mail(to: email_address, subject: "Your feedback on #{type_of_paragraph}  - #{essay_type}")
  end
end
