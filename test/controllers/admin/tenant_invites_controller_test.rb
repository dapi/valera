# frozen_string_literal: true

require 'test_helper'

class Admin::TenantInvitesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = admin_users(:superuser)
    @tenant = tenants(:one)
    host! "admin.#{ApplicationConfig.host}"
    sign_in_admin(@admin_user)
  end

  test 'index shows tenant invites' do
    get admin_tenant_invites_path
    assert_response :success
  end

  test 'new shows form with preselected tenant' do
    get new_admin_tenant_invite_path(tenant_id: @tenant.id)
    assert_response :success
    assert_select 'form'
  end

  test 'new shows form without tenant' do
    get new_admin_tenant_invite_path
    assert_response :success
    assert_select 'form'
  end

  test 'create creates invite with invited_by_admin' do
    assert_difference -> { TenantInvite.count }, 1 do
      post admin_tenant_invites_path, params: {
        tenant_invite: { tenant_id: @tenant.id, role: 'operator' }
      }
    end

    invite = TenantInvite.last
    assert_equal @tenant, invite.tenant
    assert_equal @admin_user, invite.invited_by_admin
    assert_nil invite.invited_by_user
    assert_equal 'operator', invite.role
    assert_equal 'pending', invite.status
    assert_in_delta ApplicationConfig.tenant_invite_expiration_days.days.from_now,
                    invite.expires_at,
                    1.minute

    assert_redirected_to admin_tenant_invite_path(invite)
  end

  test 'create with viewer role creates viewer invite' do
    assert_difference -> { TenantInvite.count }, 1 do
      post admin_tenant_invites_path, params: {
        tenant_invite: { tenant_id: @tenant.id, role: 'viewer' }
      }
    end

    assert_equal 'viewer', TenantInvite.last.role
  end

  test 'create with admin role creates admin invite' do
    assert_difference -> { TenantInvite.count }, 1 do
      post admin_tenant_invites_path, params: {
        tenant_invite: { tenant_id: @tenant.id, role: 'admin' }
      }
    end

    assert_equal 'admin', TenantInvite.last.role
  end

  test 'create without tenant returns error' do
    assert_no_difference -> { TenantInvite.count } do
      post admin_tenant_invites_path, params: {
        tenant_invite: { role: 'operator' }
      }
    end

    assert_response :unprocessable_entity
  end

  test 'destroy cancels invite' do
    invite = TenantInvite.create!(
      tenant: @tenant,
      invited_by_admin: @admin_user,
      role: :operator,
      expires_at: 7.days.from_now
    )

    delete admin_tenant_invite_path(invite)

    assert_redirected_to admin_tenant_invites_path
    invite.reload
    assert invite.cancelled?
    assert_not_nil invite.cancelled_at
  end

  test 'show displays invite details' do
    invite = TenantInvite.create!(
      tenant: @tenant,
      invited_by_admin: @admin_user,
      role: :operator,
      expires_at: 7.days.from_now
    )

    get admin_tenant_invite_path(invite)
    assert_response :success
  end

  test 'requires authentication' do
    delete_admin_session
    get admin_tenant_invites_path
    assert_redirected_to admin_login_path
  end

  private

  def sign_in_admin(admin_user)
    post admin_login_path, params: { email: admin_user.email, password: 'password' }
  end

  def delete_admin_session
    delete admin_logout_path
  end
end
