# frozen_string_literal: true

# Base mailer class for the application
class ApplicationMailer < ActionMailer::Base
  default from: 'from@example.com'
  layout 'mailer'
end
