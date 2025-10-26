require "test_helper"

class BookingFlowTest < ActionDispatch::IntegrationTest
  include TelegramSupport

  def message(text = 'test message')
    from = {"id":943084337,"is_bot":false,"first_name":"Danil","last_name":"Pismenny","username":"pismenny","language_code":"en","is_premium":true}
    chat = {"id":943084337,"first_name":"Danil","last_name":"Pismenny","username":"pismenny","type":"private"}
    {
      "update_id":178271355,
      "message":{"message_id":323, "from": from, "chat": chat, "date":1761379722,"text": text }
    }
  end

  setup do
    @cassete = "#{self.class.name}/#{name}/#{ApplicationConfig.llm_model}/system-prompt-#{ApplicationConfig.system_prompt_md5}/"
    @help_chat = RubyLLM.chat
    @help_chat.with_instructions File.read Rails.root.join('./test/user-system-prompt.txt')
  end

  test "сразу к делу и через вопросы букаем" do
    VCR.use_cassette @cassete, record: :new_episodes do
      user_text = "Запиши меня на покраску"
      while true do
        puts
        puts "Пользователь > #{user_text}"
        post_message user_text
        assistent_question = latest_reply_text
        puts
        puts "Ассистент > #{assistent_question}"
        user_response = @help_chat.ask assistent_question
        user_text = user_response.content
      end
      debugger
    end
  end
end
