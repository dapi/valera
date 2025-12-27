# frozen_string_literal: true

require 'test_helper'

module Admin
  module Tenants
    class InvitesControllerTest < ActionDispatch::IntegrationTest
      setup do
        @tenant = tenants(:one)
        @admin_user = admin_users(:superuser)
        host! "admin.#{ApplicationConfig.host}"
        sign_in_admin(@admin_user)
      end

      test 'create creates invite with invited_by_admin' do
        assert_difference -> { TenantInvite.count }, 1 do
          post admin_tenant_invites_path(@tenant), params: {
            tenant_invite: { role: 'operator' }
          }
        end

        assert_redirected_to [ :admin, @tenant ]

        invite = TenantInvite.last
        assert_equal @tenant, invite.tenant
        assert_equal @admin_user, invite.invited_by_admin
        assert_nil invite.invited_by_user
        assert_equal 'operator', invite.role
        assert_equal 'pending', invite.status
        assert invite.expires_at > Time.current
        assert_match(/Приглашение создано/, flash[:notice])
      end

      test 'create with admin role creates admin invite' do
        assert_difference -> { TenantInvite.count }, 1 do
          post admin_tenant_invites_path(@tenant), params: {
            tenant_invite: { role: 'admin' }
          }
        end

        invite = TenantInvite.last
        assert_equal 'admin', invite.role
      end

      test 'create with viewer role creates viewer invite' do
        assert_difference -> { TenantInvite.count }, 1 do
          post admin_tenant_invites_path(@tenant), params: {
            tenant_invite: { role: 'viewer' }
          }
        end

        invite = TenantInvite.last
        assert_equal 'viewer', invite.role
      end

      test 'destroy cancels invite' do
        invite = TenantInvite.create!(
          tenant: @tenant,
          invited_by_admin: @admin_user,
          role: :operator,
          expires_at: 7.days.from_now
        )

        delete admin_tenant_invite_path(@tenant, invite)

        assert_redirected_to [ :admin, @tenant ]
        invite.reload
        assert invite.cancelled?
        assert_not_nil invite.cancelled_at
        assert_match(/Приглашение отменено/, flash[:notice])
      end

      test 'requires authentication' do
        sign_out_admin

        post admin_tenant_invites_path(@tenant), params: {
          tenant_invite: { role: 'operator' }
        }

        assert_response :redirect
        assert_redirected_to admin_login_path
      end

      private

      def sign_in_admin(admin_user)
        post admin_login_path, params: {
          email: admin_user.email,
          password: 'password'
        }
      end

      def sign_out_admin
        delete admin_logout_path
      end
    end
  end
end
