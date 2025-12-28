# frozen_string_literal: true

require 'test_helper'

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @superuser = admin_users(:superuser)
    @user = users(:one)
    host! "admin.#{ApplicationConfig.host}"
  end

  test 'superuser can set password for user' do
    sign_in_admin(@superuser)

    patch admin_user_path(@user), params: {
      user: { password: 'new_password123' }
    }

    assert_redirected_to admin_user_path(@user)
    assert @user.reload.authenticate('new_password123'), 'Password should be updated'
  end

  test 'superuser can update user without changing password when password is blank' do
    @user.update!(password: 'original_password')
    sign_in_admin(@superuser)

    patch admin_user_path(@user), params: {
      user: { name: 'Updated Name', password: '' }
    }

    assert_redirected_to admin_user_path(@user)
    assert_equal 'Updated Name', @user.reload.name
    assert @user.authenticate('original_password'), 'Original password should still work'
  end

  private

  def sign_in_admin(admin_user)
    post admin_login_path, params: { email: admin_user.email, password: 'password' }
  end
end
