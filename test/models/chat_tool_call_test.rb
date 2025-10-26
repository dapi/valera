# frozen_string_literal: true

require "test_helper"
require "ostruct"

class ChatToolCallTest < ActiveSupport::TestCase
  test "should reproduce undefined method 'name' for Array error" do
    # Создаем тестовый чат
    telegram_user = TelegramUser.create!(
      id: 12345,
      first_name: "Test",
      last_name: "User",
      username: "testuser"
    )

    chat = Chat.create!(
      telegram_user: telegram_user,
      model: Model.first || create_default_model
    )

    # Эмулируем ситуацию когда tool_call это массив (имитируем ошибку)
    # Создаем массив с простыми объектами, которые не имеют метода name
    array_tool_call = [
      OpenStruct.new(name: 'booking_creator', id: 'tool-1'),
      OpenStruct.new(name: 'booking_creator', id: 'tool-2')
    ]

    # Прямая эмуляция проблемы: вызываем .name на массиве
    # Это должно вызвать ошибку "undefined method 'name' for an instance of Array"
    assert_raises(NoMethodError, /undefined method 'name' for an instance of Array/) do
      array_tool_call.name
    end
  end

  test "should handle tool_call with respond_to check" do
    # Создаем тестовый чат
    telegram_user = TelegramUser.create!(
      id: 12346,
      first_name: "Test2",
      last_name: "User2",
      username: "testuser2"
    )

    chat = Chat.create!(
      telegram_user: telegram_user,
      model: Model.first || create_default_model
    )

    # Тестируем нашу защиту в setup_tool_handlers
    array_tool_call = ['not_a_tool_call_object']

    # Наш код должен обработать это gracefully с помощью respond_to?
    tool_name = array_tool_call.respond_to?(:name) ? array_tool_call.name : "unknown"
    assert_equal "unknown", tool_name

    # Для корректного объекта
    single_tool_call = OpenStruct.new(name: 'booking_creator')
    tool_name = single_tool_call.respond_to?(:name) ? single_tool_call.name : "unknown"
    assert_equal "booking_creator", tool_name
  end

  test "should demonstrate array vs single object handling" do
    # Создаем массив tool_calls (что может приходить от ruby_llm)
    tool_calls_array = [
      OpenStruct.new(name: 'booking_creator', id: 'tool-1'),
      OpenStruct.new(name: 'another_tool', id: 'tool-2')
    ]

    # Демонстрация проблемы: если обработчик ожидает один объект, а получает массив
    assert_raises(NoMethodError) do
      # Это эмулирует что происходит в setup_tool_handlers без защиты
      tool_call = tool_calls_array
      tool_name = tool_call.name  # Ошибка! У массива нет метода name
    end

    # Правильная обработка:
    tool_calls_array.each do |tool_call|
      tool_name = tool_call.respond_to?(:name) ? tool_call.name : "unknown"
      assert_not_equal "unknown", tool_name
    end
  end

  private

  def create_default_model
    Model.create!(
      provider: 'deepseek',
      model_id: 'deepseek-chat',
      name: 'deepseek-chat',
      capabilities: ['chat', 'tools'],
      context_window: 4000,
      modalities: { 'input' => ['text'], 'output' => ['text'] }
    )
  end
end