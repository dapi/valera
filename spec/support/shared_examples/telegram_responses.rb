# Shared examples для Telegram ответов
# Переиспользуемые паттерны для тестирования Telegram webhook'ов

RSpec.shared_examples "successful telegram response" do |expected_text_pattern|
  it "sends response via Telegram API" do
    expect { dispatch_message(message) }
      .to respond_with_message(expected_text_pattern)
  end
end

RSpec.shared_examples "welcome message response" do
  it "sends welcome message when user starts bot" do
    expect { dispatch_command(:start) }
      .to respond_with_message(/Здравствуйте/)
  end
end

RSpec.shared_examples "car repair price response" do
  it "provides car repair cost estimate" do
    mock_llm_response("Стоимость ремонта: 7000-10000₽")

    expect { dispatch_message("сколько стоит убрать вмятину?") }
      .to respond_with_message(/(\d+)-(\d+).*₽/)
  end
end

RSpec.shared_examples "error handling response" do |error_type|
  it "handles #{error_type} gracefully" do
    expect { dispatch_message(message) }
      .to respond_with_message(/Извините, произошла ошибка/)
  end
end

RSpec.shared_examples "telegram api call made" do |method, expected_params = {}|
  it "makes #{method} call to Telegram API" do
    expect { dispatch_message(message) }
      .to make_telegram_request(bot, method)
      .with(hash_including(expected_params))
  end
end

RSpec.shared_examples "command processing" do |command_name|
  it "processes /#{command_name} command" do
    expect { dispatch_command(command_name) }
      .to make_telegram_request(bot, :sendMessage)
  end
end
