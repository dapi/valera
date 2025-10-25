# Кастомные RSpec матчеры для Telegram тестов
# Повышают читаемость тестов и инкапсулируют бизнес-логику

RSpec::Matchers.define :send_price_estimate_response do
  match do |block|
    @response = nil
    begin
      block.call
      # Проверяем содержится ли в ответе информация о цене
      last_telegram_request = Telegram.bot.requests.last
      @response = last_telegram_request[:text] if last_telegram_request
      @response&.match?(/(\d+)-(\d+).*₽|от\s*\d+.*₽|\d+.*рублей/i)
    rescue
      false
    end
  end

  description { "send price estimate response" }
  failure_message { "expected response to contain price estimate, but got: #{@response}" }
end

RSpec::Matchers.define :send_welcome_response do
  match do |block|
    @response = nil
    begin
      block.call
      last_telegram_request = Telegram.bot.requests.last
      @response = last_telegram_request[:text] if last_telegram_request
      @response&.match?(/Здравствуйте|Добро пожаловать|Здравствуйте!/)
    rescue
      false
    end
  end

  description { "send welcome response" }
  failure_message { "expected response to contain welcome message, but got: #{@response}" }
end

RSpec::Matchers.define :send_error_response do |error_type|
  match do |block|
    @response = nil
    begin
      block.call
      last_telegram_request = Telegram.bot.requests.last
      @response = last_telegram_request[:text] if last_telegram_request
      @response&.match?(/Извините, произошла ошибка|что-то пошло не так|Попробуйте еще раз/i)
    rescue
      false
    end
  end

  description { "send error response for #{error_type}" }
  failure_message { "expected response to contain error message, but got: #{@response}" }
end

RSpec::Matchers.define :create_booking_successfully do
  match do |actual|
    actual.is_a?(Hash) &&
    actual[:success] == true &&
    actual[:booking_id].present? &&
    actual[:message].present?
  end

  description { "create booking successfully" }
  failure_message { "expected booking creation to be successful, but got: #{actual}" }
end

RSpec::Matchers.define :normalize_phone_correctly do |expected_format|
  match do |actual_phone|
    normalized = normalize_phone_for_test(actual_phone)
    normalized == expected_format
  end

  description { "normalize phone #{expected_format} correctly" }
  failure_message do |actual|
    "expected #{actual} to normalize to #{expected_format}, but got #{normalize_phone_for_test(actual)}"
  end
end

RSpec::Matchers.define :persist_message_with_content do |expected_content|
  match do
    Message.last&.content == expected_content
  end

  description { "persist message with content '#{expected_content}'" }
  failure_message do
    last_message = Message.last
    if last_message
      "expected last message to have content '#{expected_content}', but got '#{last_message.content}'"
    else
      "expected a message to be persisted, but no messages found"
    end
  end
end

RSpec::Matchers.define :make_successful_booking_api_call do
  match do |block|
    @booking_created = false
    initial_count = Booking.count

    begin
      block.call
      @booking_created = Booking.count > initial_count
      @booking = Booking.last if @booking_created
    rescue
      false
    end
  end

  description { "make successful booking API call" }
  failure_message do
    if @booking_created
      "booking was created but something went wrong"
    else
      "expected booking to be created, but count didn't change"
    end
  end
end

RSpec::Matchers.define :schedule_notification_job do
  match do |job_class|
    job_scheduled = false
    begin
      expect(job_class).to have_received(:perform_later)
      job_scheduled = true
    rescue RSpec::Mocks::MockExpectationError
      false
    end
    job_scheduled
  end

  description { "schedule notification job" }
  failure_message { "expected #{job_class} to be scheduled" }
end