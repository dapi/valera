# frozen_string_literal: true

require 'test_helper'
require 'timeout'

class BookingConcurrencyTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  test 'overlapping transactions preserve both bookings with distinct numbers' do
    chat = chats(:one)
    started = Queue.new
    attempted = Queue.new
    release = Queue.new
    results = Queue.new
    first = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        Booking.transaction do
          booking = Booking.create!(chat_id: chat.id, tenant_id: chat.tenant_id, client_id: chat.client_id)
          results << booking.number
          started << true
          release.pop
        end
      end
    end
    Timeout.timeout(5) { started.pop }
    second = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        attempted << ActiveRecord::Base.connection.select_value('SELECT pg_backend_pid()')
        booking = Booking.create!(chat_id: chat.id, tenant_id: chat.tenant_id, client_id: chat.client_id)
        results << booking.number
      end
    end
    second_pid = Timeout.timeout(5) { attempted.pop }
    Timeout.timeout(5) do
      loop do
        wait_type = ActiveRecord::Base.connection.select_value(
          "SELECT wait_event_type FROM pg_stat_activity WHERE pid = #{Integer(second_pid)}"
        )
        break if wait_type == 'Lock'
        sleep 0.01
      end
    end
    # The second transaction is blocked on the row/unique-index lock before commit.
    release << true
    Timeout.timeout(5) { [ first, second ].each(&:value) }
    numbers = 2.times.map { results.pop }
    assert_equal 2, numbers.uniq.size
    assert_equal 1, (numbers.max - numbers.min)
  ensure
    release << true if release
    [ first, second ].compact.each { |thread| thread.join(5) }
  end
end
