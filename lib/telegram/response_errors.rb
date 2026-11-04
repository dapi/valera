# frozen_string_literal: true

module Telegram
  class TransientApiError < Bot::Error
    attr_reader :retry_after

    def initialize(message, retry_after: nil)
      super(message)
      @retry_after = retry_after
    end
  end

  # telegram-bot otherwise collapses 429/5xx and permanent failures into Error.
  module ResponseErrors
    def error_for_response(response)
      return super unless response.status == 429 || response.status >= 500

      data = begin
        JSON.parse(response.body)
      rescue JSON::ParserError
        {}
      end
      TransientApiError.new("Telegram API HTTP #{response.status}",
                            retry_after: data.dig('parameters', 'retry_after')&.to_i)
    end
  end
end
