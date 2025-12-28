# frozen_string_literal: true

require 'test_helper'

class ChatTopicTest < ActiveSupport::TestCase
  setup do
    @tenant = tenants(:one)
  end

  # === Validations ===

  test 'valid with key and label' do
    topic = ChatTopic.new(key: 'test_key', label: 'Test Label')
    assert topic.valid?
  end

  test 'invalid without key' do
    topic = ChatTopic.new(label: 'Test Label')
    refute topic.valid?
    assert topic.errors[:key].any?, 'Expected key to have validation errors'
  end

  test 'invalid without label' do
    topic = ChatTopic.new(key: 'test_key')
    refute topic.valid?
    assert topic.errors[:label].any?, 'Expected label to have validation errors'
  end

  test 'key must be lowercase with underscores' do
    valid_keys = %w[test test_key test_key_123 a1 key123]
    valid_keys.each do |key|
      topic = ChatTopic.new(key: key, label: 'Test')
      assert topic.valid?, "Key '#{key}' should be valid"
    end
  end

  test 'key must not start with number' do
    topic = ChatTopic.new(key: '1invalid', label: 'Test')
    refute topic.valid?
  end

  test 'key must not contain uppercase' do
    topic = ChatTopic.new(key: 'InvalidKey', label: 'Test')
    refute topic.valid?
  end

  test 'key must not contain spaces' do
    topic = ChatTopic.new(key: 'invalid key', label: 'Test')
    refute topic.valid?
  end

  test 'key must be unique within tenant scope' do
    ChatTopic.create!(key: 'unique_key', label: 'First', tenant: @tenant)
    duplicate = ChatTopic.new(key: 'unique_key', label: 'Second', tenant: @tenant)

    refute duplicate.valid?
    assert duplicate.errors[:key].any?, 'Expected key to have uniqueness validation error'
  end

  test 'same key allowed for different tenants' do
    tenant2 = tenants(:two)

    ChatTopic.create!(key: 'shared_key', label: 'First', tenant: @tenant)
    topic2 = ChatTopic.new(key: 'shared_key', label: 'Second', tenant: tenant2)

    assert topic2.valid?
  end

  test 'same key allowed for global and tenant-specific' do
    ChatTopic.create!(key: 'global_key', label: 'Global')
    topic2 = ChatTopic.new(key: 'global_key', label: 'Tenant', tenant: @tenant)

    assert topic2.valid?
  end

  # === Associations ===

  test 'belongs_to tenant is optional' do
    topic = ChatTopic.new(key: 'global', label: 'Global Topic')
    assert topic.valid?
    assert_nil topic.tenant
  end

  test 'has_many chats with nullify on destroy' do
    topic = ChatTopic.create!(key: 'chat_topic', label: 'Chat Topic')

    tg_user = TelegramUser.create!(username: 'chat_test_user', first_name: 'ChatTest')
    client = @tenant.clients.create!(telegram_user: tg_user, name: 'Chat Test Client')
    chat = @tenant.chats.create!(client: client, chat_topic: topic)

    topic.destroy!

    chat.reload
    assert_nil chat.chat_topic_id
  end

  # === Scopes ===

  test 'active scope returns only active topics' do
    active = ChatTopic.create!(key: 'active_topic', label: 'Active', active: true)
    ChatTopic.create!(key: 'inactive_topic', label: 'Inactive', active: false)

    assert_includes ChatTopic.active, active
    refute_includes ChatTopic.active, ChatTopic.find_by(key: 'inactive_topic')
  end

  test 'global scope returns topics without tenant' do
    global = ChatTopic.create!(key: 'global_scope', label: 'Global')
    tenant_topic = ChatTopic.create!(key: 'tenant_scope', label: 'Tenant', tenant: @tenant)

    assert_includes ChatTopic.global, global
    refute_includes ChatTopic.global, tenant_topic
  end

  test 'for_tenant scope returns global and tenant-specific topics' do
    global = ChatTopic.create!(key: 'for_tenant_global', label: 'Global')
    tenant_topic = ChatTopic.create!(key: 'for_tenant_specific', label: 'Tenant', tenant: @tenant)
    other_tenant_topic = ChatTopic.create!(key: 'for_tenant_other', label: 'Other', tenant: tenants(:two))

    scope = ChatTopic.for_tenant(@tenant)

    assert_includes scope, global
    assert_includes scope, tenant_topic
    refute_includes scope, other_tenant_topic
  end

  # === Class Methods ===

  test 'effective_for returns tenant topics when they exist' do
    ChatTopic.create!(key: 'effective_global', label: 'Global')
    tenant_topic = ChatTopic.create!(key: 'effective_tenant', label: 'Tenant', tenant: @tenant)

    result = ChatTopic.effective_for(@tenant)

    assert_includes result, tenant_topic
    refute_includes result, ChatTopic.find_by(key: 'effective_global')
  end

  test 'effective_for returns global topics when no tenant topics exist' do
    global = ChatTopic.create!(key: 'effective_only_global', label: 'Global')

    result = ChatTopic.effective_for(@tenant)

    assert_includes result, global
  end

  test 'fallback_topic returns other topic for tenant' do
    ChatTopic.create!(key: 'other', label: 'Other', tenant: @tenant)

    result = ChatTopic.fallback_topic(@tenant)

    assert_equal 'other', result.key
    assert_equal @tenant.id, result.tenant_id
  end

  test 'fallback_topic returns global other when no tenant other exists' do
    global_other = ChatTopic.create!(key: 'other', label: 'Other')

    result = ChatTopic.fallback_topic(@tenant)

    assert_equal global_other, result
  end

  test 'fallback_topic returns nil when no other topic exists' do
    result = ChatTopic.fallback_topic(@tenant)

    assert_nil result
  end

  # === Default Values ===

  test 'active defaults to true' do
    topic = ChatTopic.new(key: 'default_active', label: 'Default')

    assert topic.active
  end
end
