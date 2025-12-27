# frozen_string_literal: true

require 'test_helper'

module Tenants
  class MembersControllerTest < ActionDispatch::IntegrationTest
    setup do
      @tenant = tenants(:one)
      @owner = @tenant.owner
      @owner.update!(password: 'password123')
      @operator_membership = tenant_memberships(:operator_on_tenant_one)
      @admin_membership = tenant_memberships(:admin_on_tenant_one)
    end

    # === Authentication ===

    test 'redirects to login when not authenticated' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      get '/members'

      assert_redirected_to '/session/new'
    end

    # === Index ===

    test 'shows members list when authenticated as owner' do
      login_as_owner

      get '/members'

      assert_response :success
      assert_select 'h1', /Сотрудники/
    end

    test 'shows members list when authenticated as admin' do
      admin_user = users(:admin_member)
      admin_user.update!(password: 'password123')

      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: admin_user.email, password: 'password123' }

      get '/members'

      assert_response :success
    end

    test 'denies access to operator' do
      operator_user = users(:operator_user)
      operator_user.update!(password: 'password123')

      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: operator_user.email, password: 'password123' }

      get '/members'

      assert_redirected_to '/'
    end

    # === Update (role change) ===

    test 'owner can change member role' do
      login_as_owner

      assert_equal 'operator', @operator_membership.role

      patch "/members/#{@operator_membership.id}", params: { role: 'admin' }

      assert_redirected_to '/members'
      @operator_membership.reload
      assert_equal 'admin', @operator_membership.role
    end

    test 'admin can change member role' do
      admin_user = users(:admin_member)
      admin_user.update!(password: 'password123')

      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: admin_user.email, password: 'password123' }

      patch "/members/#{@operator_membership.id}", params: { role: 'viewer' }

      assert_redirected_to '/members'
      @operator_membership.reload
      assert_equal 'viewer', @operator_membership.role
    end

    test 'rejects invalid role' do
      login_as_owner

      patch "/members/#{@operator_membership.id}", params: { role: 'superadmin' }

      assert_redirected_to '/members'
      assert_match /Недопустимая роль/, flash[:alert]
      @operator_membership.reload
      assert_equal 'operator', @operator_membership.role
    end

    # === Destroy ===

    test 'owner can remove member' do
      login_as_owner

      assert_difference 'TenantMembership.count', -1 do
        delete "/members/#{@operator_membership.id}"
      end

      assert_redirected_to '/members'
    end

    test 'admin can remove member' do
      admin_user = users(:admin_member)
      admin_user.update!(password: 'password123')

      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: admin_user.email, password: 'password123' }

      assert_difference 'TenantMembership.count', -1 do
        delete "/members/#{@operator_membership.id}"
      end

      assert_redirected_to '/members'
    end

    private

    def login_as_owner
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }
    end
  end
end
