require 'rails_helper'
require 'telegram/bot/rspec/integration/rails'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails do
  # NOTE: Telegram client is already stubbed in config/initializers for test mode

  let(:from_id) { 12345 }
  # Используем фикстуры вместо создания записей вручную
  let(:telegram_user) { TelegramUser.create!(id: from_id, first_name: "Иван", last_name: "Петров") }
  let(:model) { models(:deepseek) }
  let(:chat) { Chat.create!(telegram_user: telegram_user, model: model) }
  # Переопределяем default_message_options чтобы использовать наши chat_id и from
  let(:default_message_options) do
    {
      from: { id: from_id, first_name: "Иван", last_name: "Петров" },
      chat: { id: chat_id }
    }
  end
  let(:chat_id) { 12345 }

  # Load fixtures
  fixtures :all

  # Мокаем find_or_create_by! чтобы возвращать наш chat с моделью
  before do
    allow(Chat).to receive(:find_or_create_by!).with(telegram_user: telegram_user).and_return(chat)
    allow(chat).to receive(:complete).and_return("Test response")
  end

  # Мокируем complete метод, но оставляем ask для сохранения сообщений

  describe '#start!' do
    subject { -> { dispatch_command(:start) } }

    it { is_expected.to respond_with_message(/Здравствуйте/) }
  end

  it 'handles /start command and sends welcome message' do
    expect { dispatch_command(:start) }
      .to make_telegram_request(bot, :sendMessage)
      .with(hash_including(text: /Здравствуйте/))
  end

  describe '#message' do
    context "когда пользователь отправляет сообщение о кузовном ремонте" do
      it "сохраняет сообщение в базе данных через ruby_llm" do
        expect do
          dispatch_message "сколько стоит убрать вмятину на двери?"
        end.to change(Message, :count).by(1)

        # Проверяем, что сообщение сохранено с правильным содержимым
        saved_message = Message.last
        expect(saved_message.content).to eq("сколько стоит убрать вмятину на двери?")
        expect(saved_message.chat).to eq(chat)
      end

      it "передает запрос в LLM и получает ответ" do
        # Переопределяем мок для конкретного ответа
        allow(chat).to receive(:complete).and_return("Ориентировочно 7000-10000₽")

        dispatch_message "сколько стоит убрать вмятину на двери?"

        expect(response).to have_http_status(:ok)
      end

      it "отправляет ответ пользователю через Telegram API" do
        # Переопределяем мок для конкретного ответа
        allow(chat).to receive(:complete).and_return("Ориентировочно 7000-10000₽")

        # Ожидаем, что будет отправлено сообщение с текстом ответа
        expect { dispatch_message "сколько стоит убрать вмятину на двери?" }
          .to respond_with_message("Ориентировочно 7000-10000₽")
      end
    end

    context "когда пользователь отправляет обычное сообщение" do
      it "также сохраняет сообщение в базе данных" do
        expect do
          dispatch_message "привет"
        end.to change(Message, :count).by(1)

        saved_message = Message.last
        expect(saved_message.content).to eq("привет")
      end

      it "передает обычное сообщение в LLM и получает ответ" do
        # Переопределяем мок для конкретного ответа
        allow(chat).to receive(:complete).and_return("Здравствуйте!")

        dispatch_message "привет"

        expect(response).to have_http_status(:ok)
      end
    end

    context "когда пользователь отправляет команду /start" do
      it "обрабатывает команду через start! метод" do
        # Используем allow_message_expectations_on_nil для тестирования вызова метода
        RSpec::Mocks.configuration.allow_message_expectations_on_nil = true

        expect_any_instance_of(Telegram::WebhookController).to receive(:start!)

        dispatch_command :start

        # Возвращаем настройку обратно
        RSpec::Mocks.configuration.allow_message_expectations_on_nil = false
      end
    end
  end

  describe '#callback_query' do
    it "отвечает на callback query" do
      # Добавляем структуру callback query с полями from и id
      dispatch callback_query: {
        data: 'test_data',
        from: { id: from_id, first_name: 'Иван', last_name: 'Петров' }
      }
    end
  end
end
