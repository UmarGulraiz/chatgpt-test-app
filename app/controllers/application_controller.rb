class ApplicationController < ActionController::Base
  before_action :set_mailer_host

  def set_mailer_host
    ActionMailer::Base.default_url_options[:host] = ENV['MAIL_HOST']
  end
end
