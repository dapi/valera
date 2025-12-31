# frozen_string_literal: true

# Channel for streaming chat messages with tenant authorization
#
# Extends Turbo::StreamsChannel to add tenant-based access control.
# Only users with access to the chat's tenant can subscribe.
#
# @example In views
#   = turbo_stream_from chat, channel: TenantChatsChannel
#
# @example In models (broadcasts)
#   broadcasts_to ->(message) { message.chat }, inserts_by: :append
#
class TenantChatsChannel < Turbo::StreamsChannel
  def subscribed
    if authorized?
      super
    else
      reject
    end
  end

  private

  def authorized?
    return false unless current_user
    return false unless chat

    current_user.has_access_to?(chat.tenant)
  end

  def chat
    return @chat if defined?(@chat)

    @chat = find_chat_from_stream_name
  end

  # Decodes the signed stream name to find the Chat
  #
  # Stream name is a base64-encoded GlobalID (e.g., "Z2lkOi8vdmFsZXJhL0NoYXQvMQ")
  # Decoded format: "gid://valera/Chat/1"
  #
  # @return [Chat, nil]
  def find_chat_from_stream_name
    stream_name = verified_stream_name_from_params
    return nil unless stream_name

    # Decode the base64-encoded GlobalID
    decoded = Base64.urlsafe_decode64(stream_name)
    gid = GlobalID.parse(decoded)
    return nil unless gid

    record = gid.find
    record.is_a?(Chat) ? record : nil
  rescue ActiveRecord::RecordNotFound
    nil
  end
end
