# frozen_string_literal: true

module Tenants
  # Dashboard home page controller.
  # Shows overview statistics for the tenant.
  #
  class HomeController < ApplicationController
    # GET /
    def show
      # Phase 2 will add statistics
      @tenant = Current.tenant
    end
  end
end
