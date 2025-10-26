# frozen_string_literal: true

# Copyright © 2023 Danil Pismenny <danil@brandymint.ru>

module Telegram
  # Отрабатываем ошибки телеграма
  module RescueErrors
    extend ActiveSupport::Concern
    included do
      rescue_from Telegram::Bot::Forbidden, with: :bot_forbidden
      rescue_from Telegram::Bot::Error, with: :bot_error
    end

    private

    # Пользователь написал в бота и заблокировал его (наверное добавлен где-то в канале или тп)
    def bot_forbidden(error)
      Bugsnag.notify error
      Rails.logger.error "#{error} #{chat.to_json}"
    end

    # У бота уже нет доступа отвечать в чат
    #
    def bot_error(error)
      Bugsnag.notify error
      Rails.logger.error "#{error} #{chat.to_json}"
    end
  end
end
