# frozen_string_literal: true

require 'test_helper'

class TenantChatsChannelTest < ActionCable::Channel::TestCase
  setup do
    @tenant = tenants(:one)
    @chat = chats(:one)
    @user = users(:one)
    @other_tenant = tenants(:two)
    @other_user = users(:two)
  end

  test 'rejects subscription when user is not authenticated' do
    stub_connection(current_user: nil)

    subscribe_to_chat(@chat)

    assert subscription.rejected?
  end

  test 'rejects subscription when user has no access to tenant' do
    # Ensure other_user has no access to the chat's tenant
    @other_user.tenant_memberships.where(tenant: @tenant).destroy_all

    stub_connection(current_user: @other_user)

    subscribe_to_chat(@chat)

    assert subscription.rejected?
  end

  test 'accepts subscription when user is tenant owner' do
    # Ensure user is owner of the tenant
    @tenant.update!(owner: @user)

    stub_connection(current_user: @user)

    subscribe_to_chat(@chat)

    assert subscription.confirmed?
  end

  test 'accepts subscription when user is tenant member' do
    # Ensure user has membership to tenant
    unless @user.has_access_to?(@tenant)
      TenantMembership.create!(tenant: @tenant, user: @user)
    end

    stub_connection(current_user: @user)

    subscribe_to_chat(@chat)

    assert subscription.confirmed?
  end

  private

  def subscribe_to_chat(chat)
    # Generate the signed stream name that turbo_stream_from would create
    signed_stream_name = Turbo::StreamsChannel.signed_stream_name(chat)

    subscribe(signed_stream_name: signed_stream_name)
  end
end
