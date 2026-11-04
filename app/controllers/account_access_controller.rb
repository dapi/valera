# frozen_string_literal: true

class AccountAccessController < ApplicationController
  include UserSession
  layout 'account_access'
  before_action -> { response.headers['Cache-Control'] = 'no-store' }
end
