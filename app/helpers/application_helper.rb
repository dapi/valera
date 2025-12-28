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

  # Форматирует стоимость в долларах
  # format_cost(0.123456) => "$0.12"
  # format_cost(1.5) => "$1.50"
  def format_cost(amount)
    return '$0.00' if amount.nil? || amount.zero?

    "$#{format('%.2f', amount)}"
  end

  # Форматирует количество токенов с разделителями тысяч
  # format_tokens(1234567) => "1,234,567"
  def format_tokens(count)
    return '0' if count.nil? || count.zero?

    number_with_delimiter(count)
  end
end
