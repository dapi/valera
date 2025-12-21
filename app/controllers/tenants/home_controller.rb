# frozen_string_literal: true

module Tenants
  # Dashboard home page controller.
  # Shows overview statistics for the tenant.
  #
  class HomeController < ApplicationController
    # GET /
    # GET /?period=7|30
    def show
      @period = params[:period]&.to_i || 7
      @period = 7 unless [ 7, 30 ].include?(@period)
      @stats = DashboardStatsService.new(current_tenant, period: @period).call
    end
  end
end
