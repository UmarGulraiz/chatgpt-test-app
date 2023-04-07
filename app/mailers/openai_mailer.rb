class OpenaiMailer < ApplicationMailer
  default from: "umar.gulraiz1@gmail.com"

  def send_response(suggestion_array, email_address)
    @suggestions = suggestion_array
    mail(to: email_address, subject: "Essay suggestions")
  end
end
