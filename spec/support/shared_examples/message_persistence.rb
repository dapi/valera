# Shared examples для сохранения сообщений
# Переиспользуемые паттерны для тестирования persistence логики

RSpec.shared_examples "message persistence" do
  it "persists message in database" do
    message_content = if respond_to?(:message)
                        message
                      elsif respond_to?(:car_repair_message)
                        car_repair_message
                      else
                        respond_to?(:regular_message) ? regular_message : "test message"
                      end

    expect { dispatch_message(message_content) }
      .to change(Message, :count).by(1)

    saved_message = Message.last
    expect(saved_message.content).to eq(message_content)
    expect(saved_message.chat).to eq(chat)
  end
end

RSpec.shared_examples "chat message association" do
  it "associates message with correct chat" do
    dispatch_message(message)

    saved_message = Message.last
    expect(saved_message.chat).to eq(chat)
    expect(saved_message.chat.telegram_user).to eq(telegram_user)
  end
end

RSpec.shared_examples "no message persistence on error" do
  it "does not persist message when error occurs" do
    initial_count = Message.count

    expect { dispatch_message(message) }
      .not_to change(Message, :count)
  end
end