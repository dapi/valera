# frozen_string_literal: true

# Модель пользователя Telegram
#
# Представляет пользователя, который взаимодействует с ботом.
# Хранит данные пользователя и обеспечивает совместимость с системой аналитики.
#
# @attr [Integer] id уникальный идентификатор пользователя Telegram
# @attr [String] first_name имя пользователя
# @attr [String] last_name фамилия пользователя
# @attr [String] username пользовательнейм
# @attr [String] photo_url URL аватара
# @attr [DateTime] created_at время создания записи
# @attr [DateTime] updated_at время обновления записи
#
# @example Создание пользователя из данных Telegram
#   user = TelegramUser.find_or_create_by_telegram_data!(telegram_data)
#
# @see Chat для связи с диалогами пользователя
# @see AnalyticsService для аналитики
# @author Danil Pismenny
# @since 0.1.0
class TelegramUser < ApplicationRecord
  has_one :chat, dependent: :delete

  # Возвращает имя пользователя для отображения
  #
  # @return [String] first_name, username или "##{id}" если нет данных
  # @example
  #   user.name #=> "Иван"
  #   user.name #=> "@username"
  #   user.name #=> "#123456789"
  def name
    first_name.presence || magic_username.presence || "##{id}"
  end

  # Возвращает пользовательнейм с символом @
  #
  # @return [String, nil] "@username" или nil если username отсутствует
  # @example
  #   user.magic_username #=> "@john_doe"
  #   user.magic_username #=> nil
  def magic_username
    "@#{username}" if username
  end

  # Возвращает полное имя пользователя
  #
  # @return [String] объединенные first_name и last_name
  # @example
  #   user.full_name #=> "Иван Иванов"
  #   user.full_name #=> "Иван"
  def full_name
    [first_name, last_name].compact.join(' ').strip
  end

  # Возвращает chat_id для совместимости с аналитикой
  #
  # @return [Integer] ID пользователя (для аналитики chat_id = telegram_user_id)
  # @note Используется для совместимости с AnalyticsService
  def chat_id
    id
  end

  # Находит или создает пользователя по данным от Telegram
  #
  # @param data [Hash] данные пользователя от Telegram API
  # @option data [Integer] 'id' ID пользователя
  # @option data [String] 'first_name' имя пользователя
  # @option data [String] 'last_name' фамилия пользователя
  # @option data [String] 'username' пользовательнейм
  # @option data [String] 'photo_url' URL аватара
  # @return [TelegramUser] найденный или созданный пользователь
  # @raise [ActiveRecord::RecordInvalid] при ошибке валидации
  # @example
  #   user = TelegramUser.find_or_create_by_telegram_data!(telegram_data)
  def self.find_or_create_by_telegram_data!(data)
    tu = create_with(
      data.slice('first_name', 'last_name', 'username', 'photo_url')
    )
         .find_or_create_by!(id: data.fetch('id'))

    tu.update_from_chat! data
    tu
  end

  # Обновляет данные пользователя из информации о чате
  #
  # @param chat [Hash] данные чата от Telegram API
  # @option chat [String] 'first_name' имя пользователя
  # @option chat [String] 'last_name' фамилия пользователя
  # @option chat [String] 'username' пользовательнейм
  # @return [void]
  # @note Сохраняет изменения только если данные действительно изменились
  # @example
  #   user.update_from_chat!({"first_name" => "Иван", "username" => "ivan123"})
  def update_from_chat!(chat)
    assign_attributes chat.slice(*%w[first_name last_name username])
    return unless changed?

    save!
  end
end
