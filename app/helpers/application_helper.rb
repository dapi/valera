# frozen_string_literal: true

# Provides helper methods for the application views
module ApplicationHelper
  # Русская плюрализация
  # pluralize_ru(1, 'бот', 'бота', 'ботов') => 'бот'
  # pluralize_ru(2, 'бот', 'бота', 'ботов') => 'бота'
  # pluralize_ru(5, 'бот', 'бота', 'ботов') => 'ботов'
  def pluralize_ru(count, one, few, many)
    return many if (11..14).include?(count % 100)

    case count % 10
    when 1 then one
    when 2, 3, 4 then few
    else many
    end
  end

  # Форматирует время в относительный формат для чатов
  # chat_time_ago(1.hour.ago) => "около 1 часа назад"
  # chat_time_ago(3.days.ago) => "3 дня назад"
  def chat_time_ago(time)
    return '' unless time

    time_ago_in_words(time, include_seconds: false)
  end
end
