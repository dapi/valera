# frozen_string_literal: true

require 'test_helper'

class TenantInviteTest < ActiveSupport::TestCase
  setup do
    @tenant = tenants(:one)
    @user = users(:one)
  end

  test 'generates token on create' do
    invite = TenantInvite.create!(
      tenant: @tenant,
      invited_by_user: @user,
      role: :operator,
      expires_at: 7.days.from_now
    )

    assert_not_nil invite.token
    assert invite.token.start_with?('MBR_'), 'Token must start with MBR_'
  end

  test 'has default role of viewer' do
    invite = TenantInvite.new(
      tenant: @tenant,
      invited_by_user: @user,
      expires_at: 7.days.from_now
    )

    assert invite.valid?
    assert_equal 'viewer', invite.role
  end

  test 'validates presence of expires_at' do
    invite = TenantInvite.new(
      tenant: @tenant,
      invited_by_user: @user,
      role: :operator
    )

    assert_not invite.valid?
    assert invite.errors[:expires_at].present?
  end

  test 'validates token uniqueness' do
    invite1 = TenantInvite.create!(
      tenant: @tenant,
      invited_by_user: @user,
      role: :operator,
      expires_at: 7.days.from_now
    )

    invite2 = TenantInvite.new(
      tenant: @tenant,
      invited_by_user: @user,
      role: :viewer,
      token: invite1.token,
      expires_at: 7.days.from_now
    )

    assert_not invite2.valid?
    assert invite2.errors[:token].present?
  end

  test 'validates inviter must be present' do
    invite = TenantInvite.new(
      tenant: @tenant,
      role: :operator,
      expires_at: 7.days.from_now
    )

    assert_not invite.valid?
    assert invite.errors[:base].present?
  end

  test 'valid with invited_by_user' do
    invite = TenantInvite.new(
      tenant: @tenant,
      invited_by_user: @user,
      role: :operator,
      expires_at: 7.days.from_now
    )

    assert invite.valid?
  end

  test 'valid with invited_by_admin' do
    admin = admin_users(:superuser)
    invite = TenantInvite.new(
      tenant: @tenant,
      invited_by_admin: admin,
      role: :operator,
      expires_at: 7.days.from_now
    )

    assert invite.valid?
  end

  test 'invited_by returns user when invited_by_user is set' do
    invite = TenantInvite.new(
      tenant: @tenant,
      invited_by_user: @user,
      role: :operator,
      expires_at: 7.days.from_now
    )

    assert_equal @user, invite.invited_by
  end

  test 'invited_by returns admin when invited_by_admin is set' do
    admin = admin_users(:superuser)
    invite = TenantInvite.new(
      tenant: @tenant,
      invited_by_admin: admin,
      role: :operator,
      expires_at: 7.days.from_now
    )

    assert_equal admin, invite.invited_by
  end

  test 'invited_by_name returns name from user' do
    invite = TenantInvite.new(
      tenant: @tenant,
      invited_by_user: @user,
      role: :operator,
      expires_at: 7.days.from_now
    )

    assert_equal(@user.name || @user.email, invite.invited_by_name)
  end

  test 'active scope returns pending invites not expired' do
    active_invite = TenantInvite.create!(
      tenant: @tenant,
      invited_by_user: @user,
      role: :operator,
      expires_at: 7.days.from_now
    )

    expired_invite = TenantInvite.create!(
      tenant: @tenant,
      invited_by_user: @user,
      role: :viewer,
      expires_at: 1.day.ago
    )

    assert_includes TenantInvite.active, active_invite
    assert_not_includes TenantInvite.active, expired_invite
  end

  test 'accept! updates status and accepted_by' do
    invite = TenantInvite.create!(
      tenant: @tenant,
      invited_by_user: @user,
      role: :operator,
      expires_at: 7.days.from_now
    )

    accepting_user = users(:two)
    invite.accept!(accepting_user)

    assert invite.accepted?
    assert_equal accepting_user, invite.accepted_by
    assert_not_nil invite.accepted_at
  end

  test 'cancel! updates status and cancelled_at' do
    invite = TenantInvite.create!(
      tenant: @tenant,
      invited_by_user: @user,
      role: :operator,
      expires_at: 7.days.from_now
    )

    invite.cancel!

    assert invite.cancelled?
    assert_not_nil invite.cancelled_at
  end

  test 'expired? returns true for pending invites past expiration' do
    invite = TenantInvite.create!(
      tenant: @tenant,
      invited_by_user: @user,
      role: :operator,
      expires_at: 1.day.ago
    )

    assert invite.expired?
  end

  test 'expired? returns false for active invites' do
    invite = TenantInvite.create!(
      tenant: @tenant,
      invited_by_user: @user,
      role: :operator,
      expires_at: 7.days.from_now
    )

    assert_not invite.expired?
  end

  test 'expired? returns false for accepted invites' do
    invite = TenantInvite.create!(
      tenant: @tenant,
      invited_by_user: @user,
      role: :operator,
      expires_at: 1.day.ago,
      status: :accepted
    )

    assert_not invite.expired?
  end

  test 'telegram_url generates correct URL' do
    invite = TenantInvite.create!(
      tenant: @tenant,
      invited_by_user: @user,
      role: :operator,
      expires_at: 7.days.from_now
    )

    expected_url = "https://t.me/#{ApplicationConfig.platform_bot_username}?start=#{invite.token}"
    assert_equal expected_url, invite.telegram_url
  end

  test 'role enum has viewer, operator, admin' do
    assert_equal({ 'viewer' => 0, 'operator' => 1, 'admin' => 2 }, TenantInvite.roles)
  end

  test 'status enum has pending, accepted, expired, cancelled' do
    assert_equal({ 'pending' => 0, 'accepted' => 1, 'expired' => 2, 'cancelled' => 3 }, TenantInvite.statuses)
  end
end
