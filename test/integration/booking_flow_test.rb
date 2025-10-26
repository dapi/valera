require "test_helper"

class BookingFlowTest < ActionDispatch::IntegrationTest
  include TelegramSupport

  def message(text = 'test message')
    from = { id: 943_084_337, is_bot: false, first_name: "Danil", last_name: "Pismenny", username: "pismenny",
             language_code: "en", is_premium: true }
    chat = { id: 943_084_337, first_name: "Danil", last_name: "Pismenny", username: "pismenny", type: "private" }
    {
      update_id: 178_271_355,
      message: { message_id: 323, from: from, chat: chat, date: 1_761_379_722, text: text }
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

      tool_calls_count = ToolCall.count
      while true
        puts
        puts "Пользователь >"
        puts user_text.gsub(/^/, "\t")
        post_message user_text
        assistent_question = latest_reply_text
        puts
        puts "Ассистент >"
        puts assistent_question.gsub(/^/, "\t")

        break if ToolCall.count > tool_calls_count

        # Можно было бы прерваться после слов благодрност полоьзователя, но тогда мы получаем ошибку в ruby_llm
        user_response = @help_chat.ask assistent_question
        user_text = user_response.content
      end

      assert true
    end
  end
end
