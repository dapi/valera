# frozen_string_literal: true

require 'test_helper'

class BookingFlowTest < ActionDispatch::IntegrationTest
  include TelegramSupport

  def message(text = 'test message')
    from = { id: 943_084_337, is_bot: false, first_name: 'Danil', last_name: 'Pismenny', username: 'pismenny',
             language_code: 'en', is_premium: true }
    chat = { id: 943_084_337, first_name: 'Danil', last_name: 'Pismenny', username: 'pismenny', type: 'private' }
    {
      update_id: 178_271_355,
      message: { message_id: 323, from: from, chat: chat, date: 1_761_379_722, text: text }
    }
  end

  setup do
    @help_chat = RubyLLM.chat
    @help_chat.with_instructions Rails.root.join('./test/user-system-prompt.txt').read
  end

  def cassete_name
    [
      self.class.name.to_s,
      name,
      ApplicationConfig.llm_provider,
      ApplicationConfig.llm_model,
      "system-prompt-#{ApplicationConfig.system_prompt_md5}"
    ].join('/')
  end

  def dialog(first_question)
    VCR.use_cassette cassete_name, record: :new_episodes do
      user_text = first_question

      tool_calls_count = ToolCall.count
      counts = 0
      loop do
        puts
        puts 'Пользователь >'
        puts user_text.gsub(/^/, "\t")
        post_message user_text
        assistent_question = latest_reply_text
        if ToolCall.count > tool_calls_count
          counts += 1
          break if counts > 2
        end
        puts
        puts 'Ассистент >'
        puts assistent_question.gsub(/^/, "\t")

        # Можно было бы прерваться после слов благодрност полоьзователя, но тогда мы получаем ошибку в ruby_llm
        user_response = @help_chat.ask assistent_question
        user_text = user_response.content
      end

      error_message = 'Извините, произошла ошибка. Попробуйте еще раз.'
      assert_not_equal latest_reply_text, error_message
    end
  end

  test 'сразу к делу и через вопросы букаем' do
    dialog 'Запиши меня на покраску'
  end

  test 'сколько стоит покрасить бампер' do
    dialog 'Сколько стоит покрасить бампер?'
  end
end
