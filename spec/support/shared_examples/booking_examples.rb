# Shared examples для booking функциональности
# Переиспользуемые паттерны для тестирования создания записей

RSpec.shared_examples "successful booking creation" do
  it "creates booking with correct parameters" do
    expect(BookingNotificationJob).to receive(:perform_later)

    result = BookingCreatorTool.call(parameters: params, context: context)

    expect(result[:success]).to be true
    expect(result[:booking_id]).to be_present
  end

  it "normalizes phone number correctly" do
    allow(BookingNotificationJob).to receive(:perform_later)

    BookingCreatorTool.call(parameters: params, context: context)

    booking = Booking.last
    expect(booking.meta['customer_phone']).to match(/\+7\(\d{3}\)\d{3}-\d{2}-\d{2}/)
  end

  it "maintains proper relationships" do
    allow(BookingNotificationJob).to receive(:perform_later)

    BookingCreatorTool.call(parameters: params, context: context)

    booking = Booking.last
    expect(booking.telegram_user).to eq(context[:telegram_user])
    expect(booking.chat).to eq(context[:chat])
  end
end

RSpec.shared_examples "booking creation with invalid parameters" do
  it "returns error response" do
    initial_count = Booking.count

    result = BookingCreatorTool.call(parameters: params, context: context)

    expect(result[:success]).to be false
    expect(result[:message]).to include('Не удалось создать запись')
    expect(Booking.count).to eq(initial_count)
  end
end

RSpec.shared_examples "phone number normalization" do
  it "normalizes phone number correctly" do
    allow(BookingNotificationJob).to receive(:perform_later)

    BookingCreatorTool.call(parameters: params, context: context)

    booking = Booking.last
    expected_phone = normalize_phone_for_test(params[:customer_phone])
    expect(booking.meta['customer_phone']).to eq(expected_phone)
  end
end

RSpec.shared_examples "booking notification job scheduling" do
  it "schedules BookingNotificationJob" do
    expect(BookingNotificationJob).to receive(:perform_later)

    BookingCreatorTool.call(parameters: params, context: context)
  end
end