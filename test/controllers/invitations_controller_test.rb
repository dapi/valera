# frozen_string_literal: true

require 'test_helper'

class InvitationsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  setup do
    host! ApplicationConfig.host
    @tenant = tenants(:one)
    @owner = users(:one)
    @owner.update!(password: 'owner-password')
    @invite = TenantInvite.create!(tenant: @tenant, invited_by_user: @owner,
                                   role: :operator, expires_at: 7.days.from_now)
  end

  test 'link invitation requires verified mailbox before granting access' do
    get '/invitations'
    assert_response :success
    assert_select '[data-controller="fragment-token"]'

    post '/invitations/open', params: { token: @invite.token }
    assert_redirected_to '/invitations/email'
    post '/invitations/confirm', params: { name: 'New colleague', password: 'secret-password' }
    assert_redirected_to '/invitations/email'
    assert @invite.reload.pending?

    assert_enqueued_emails 1 do
      post '/invitations/email', params: { email: 'Colleague@example.com' }
    end
    verify_email(@invite, 'colleague@example.com')
    get '/invitations/confirm'
    assert_response :success
    assert_select 'input[name="password_confirmation"]'

    assert_difference [ 'User.count', 'TenantMembership.count' ], 1 do
      post '/invitations/confirm', params: { name: 'New colleague', password: 'secret-password',
                                            password_confirmation: 'secret-password' }
    end
    assert_redirected_to '/login/select'
    user = User.find_by!(email: 'colleague@example.com')
    assert user.authenticate('secret-password')
    assert user.membership_for(@tenant).operator?
    assert_equal user, @invite.reload.accepted_by
    assert_equal @owner.id, @tenant.reload.owner_id

    assert_no_difference 'TenantMembership.count' do
      post '/invitations/open', params: { token: @invite.token }
    end
    assert_redirected_to '/login'
  end

  test 'existing user must authenticate and keeps existing password and role' do
    existing = users(:admin_member)
    existing.update!(password: 'existing-password')
    verify_email(@invite, existing.email)

    assert_no_difference 'TenantMembership.count' do
      post '/invitations/confirm', params: { password: 'incorrect-password' }
    end
    assert_response :unprocessable_entity
    assert existing.reload.authenticate('existing-password')
    assert @invite.reload.pending?

    post '/invitations/confirm', params: { password: 'existing-password' }
    assert_redirected_to '/login/select'
    assert existing.reload.membership_for(@tenant).admin?
    assert @invite.reload.accepted?
  end

  test 'bound email cannot be changed or accepted through an unverified session' do
    @invite.update!(email: 'specific@example.com')
    post '/invitations/open', params: { token: @invite.token }
    assert_no_enqueued_emails do
      post '/invitations/email', params: { email: 'other@example.com' }
    end
    assert_response :unprocessable_entity
    post '/invitations/verify', params: { token: @invite.email_verification_token('other@example.com') }
    assert_redirected_to '/login'
    assert @invite.reload.pending?
  end

  test 'cancelled or expired invite cannot be accepted after email verification' do
    verify_email(@invite, 'colleague@example.com')
    @invite.cancel!
    assert_no_difference 'User.count' do
      post '/invitations/confirm', params: { name: 'New colleague', password: 'secret-password',
                                            password_confirmation: 'secret-password' }
    end
    assert_redirected_to '/login'

    @invite.update!(status: :pending, expires_at: 1.minute.ago)
    post '/invitations/open', params: { token: @invite.token }
    assert_redirected_to '/login'
  end

  test 'email verification expires and tampered token fails' do
    token = @invite.email_verification_token('colleague@example.com')
    travel 31.minutes do
      post '/invitations/verify', params: { token: token }
      assert_redirected_to '/login'
    end
    post '/invitations/verify', params: { token: token + 'tampered' }
    assert_redirected_to '/login'
  end

  test 'new account requires confirmation and cannot become owner of an ownerless tenant' do
    @invite.update!(tenant: tenants(:no_owner))
    verify_email(@invite, 'colleague@example.com')
    assert_no_difference 'User.count' do
      post '/invitations/confirm', params: { name: 'New colleague', password: 'secret-password' }
    end
    assert_response :unprocessable_entity
    post '/invitations/confirm', params: { name: 'New colleague', password: 'secret-password',
                                          password_confirmation: 'secret-password' }
    assert_redirected_to '/login/select'
    assert_nil @invite.tenant.reload.owner_id
  end

  test 'owner can create an email invite and link invite while operator cannot' do
    host! "#{@tenant.key}.#{ApplicationConfig.host}"
    post '/session', params: { email: @owner.email, password: 'owner-password' }
    assert_enqueued_emails 1 do
      assert_difference 'TenantInvite.count', 1 do
        post '/members', params: { role: 'viewer', email: 'Invited@example.com' }
      end
    end
    invite = TenantInvite.order(:id).last
    assert_equal 'invited@example.com', invite.email
    assert invite.viewer?
    assert_redirected_to invite_tenant_members_path(id: invite.id)
    follow_redirect!
    assert_response :success
    assert_select 'input#invite-url' do |input|
      assert_equal invite.web_url, input.first['value']
      assert_includes input.first['value'], '#token='
    end

    assert_no_enqueued_emails do
      post '/members', params: { role: 'operator' }
    end
    invite = TenantInvite.order(:id).last
    assert_nil invite.email

    operator = users(:operator_user)
    operator.update!(password: 'operator-password')
    delete '/session'
    post '/session', params: { email: operator.email, password: 'operator-password' }
    assert_no_difference 'TenantInvite.count' do
      post '/members', params: { role: 'admin', email: 'outside@example.com' }
    end
  end

  test 'invitation mail keeps verification token in fragment and omits passwords' do
    mail = AccountMailer.invitation(@invite, 'colleague@example.com').message
    assert_equal [ 'colleague@example.com' ], mail.to
    assert_includes mail.body.decoded, '/invitations/accept#token='
    assert_not_includes mail.body.decoded, 'secret-password'
  end

  private

  def verify_email(invite, email)
    post '/invitations/verify', params: { token: invite.email_verification_token(email) }
    assert_redirected_to '/invitations/confirm'
  end
end
