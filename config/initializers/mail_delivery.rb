# frozen_string_literal: true

if ApplicationConfig.smtp_address.present?
  ActionMailer::Base.delivery_method = :smtp
  ActionMailer::Base.smtp_settings = {
    address: ApplicationConfig.smtp_address,
    port: ApplicationConfig.smtp_port || 465,
    domain: ApplicationConfig.host,
    user_name: ApplicationConfig.smtp_username,
    password: ApplicationConfig.smtp_password,
    authentication: :login,
    ssl: ApplicationConfig.smtp_ssl != false,
    enable_starttls_auto: ApplicationConfig.smtp_ssl == false,
    open_timeout: 10,
    read_timeout: 10
  }
  ActionMailer::Base.raise_delivery_errors = true
end
