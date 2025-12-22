# frozen_string_literal: true

# Base mailer class for the application
class ApplicationMailer < ActionMailer::Base
  default from: -> { ApplicationConfig.support_email }
  layout 'mailer'
end
