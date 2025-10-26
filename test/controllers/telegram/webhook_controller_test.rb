# frozen_string_literal: true

require "test_helper"

class Telegram::WebhookControllerTest < ActionDispatch::IntegrationTest
  test "message method exists" do
    controller = Telegram::WebhookController.new
    assert_respond_to controller, :message
  end

  test "start! method exists" do
    controller = Telegram::WebhookController.new
    assert_respond_to controller, :start!
  end
end
