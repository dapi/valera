# frozen_string_literal: true

require 'test_helper'

class TenantMembershipTest < ActiveSupport::TestCase
  setup do
    @tenant = tenants(:one)
    @user = users(:operator_user)
    @membership = tenant_memberships(:operator_on_tenant_one)
  end

  test 'valid membership' do
    assert @membership.valid?
  end

  test 'requires tenant' do
    membership = TenantMembership.new(user: @user, role: :viewer)
    assert_not membership.valid?
    assert_includes membership.errors[:tenant], I18n.t('errors.messages.required')
  end

  test 'requires user' do
    membership = TenantMembership.new(tenant: @tenant, role: :viewer)
    assert_not membership.valid?
    assert_includes membership.errors[:user], I18n.t('errors.messages.required')
  end

  test 'requires role' do
    membership = TenantMembership.new(tenant: @tenant, user: users(:two))
    membership.role = nil
    assert_not membership.valid?
    assert_includes membership.errors[:role], I18n.t('errors.messages.blank')
  end

  test 'user can only have one membership per tenant' do
    duplicate = TenantMembership.new(
      tenant: @tenant,
      user: @user,
      role: :admin
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], I18n.t('errors.messages.taken')
  end

  test 'user can have memberships in multiple tenants' do
    membership = TenantMembership.new(
      tenant: tenants(:two),
      user: @user,
      role: :viewer
    )
    assert membership.valid?
  end

  test 'role enum values' do
    assert_equal 0, TenantMembership.roles[:viewer]
    assert_equal 1, TenantMembership.roles[:operator]
    assert_equal 2, TenantMembership.roles[:admin]
  end

  test 'viewer cannot respond to clients' do
    membership = TenantMembership.new(role: :viewer)
    assert_not membership.can_respond_to_clients?
  end

  test 'operator can respond to clients' do
    membership = TenantMembership.new(role: :operator)
    assert membership.can_respond_to_clients?
  end

  test 'admin can respond to clients' do
    membership = TenantMembership.new(role: :admin)
    assert membership.can_respond_to_clients?
  end

  test 'viewer cannot manage settings' do
    membership = TenantMembership.new(role: :viewer)
    assert_not membership.can_manage_settings?
  end

  test 'operator cannot manage settings' do
    membership = TenantMembership.new(role: :operator)
    assert_not membership.can_manage_settings?
  end

  test 'admin can manage settings' do
    membership = TenantMembership.new(role: :admin)
    assert membership.can_manage_settings?
  end

  test 'viewer cannot manage members' do
    membership = TenantMembership.new(role: :viewer)
    assert_not membership.can_manage_members?
  end

  test 'operator cannot manage members' do
    membership = TenantMembership.new(role: :operator)
    assert_not membership.can_manage_members?
  end

  test 'admin can manage members' do
    membership = TenantMembership.new(role: :admin)
    assert membership.can_manage_members?
  end

  test 'tenant_invite association is optional' do
    membership = TenantMembership.new(
      tenant: tenants(:one),
      user: users(:viewer_user),
      role: :viewer,
      tenant_invite: nil
    )
    assert membership.valid?
  end
end
