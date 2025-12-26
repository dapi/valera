# frozen_string_literal: true

module Admin
  class TenantMembershipsController < Admin::ApplicationController
    before_action :authorize_superuser!, only: %i[new create edit update destroy]
  end
end
