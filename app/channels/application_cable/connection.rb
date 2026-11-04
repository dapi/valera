# frozen_string_literal: true

module ApplicationCable
  # Base ActionCable connection with user authentication
  #
  # Identifies the WebSocket connection by current_user,
  # allowing channels to access the authenticated user.
  #
  # @example Accessing current_user in a channel
  #   class MyChannel < ApplicationCable::Channel
  #     def subscribed
  #       if current_user.has_access_to?(some_resource)
  #         stream_from "my_stream"
  #       else
  #         reject
  #       end
  #     end
  #   end
  #
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      user_id = request.session[:user_id]
      user = User.find_by(id: user_id) if user_id

      user || reject_unauthorized_connection
    end
  end
end
