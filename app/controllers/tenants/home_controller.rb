# frozen_string_literal: true

module Tenants
  # Dashboard home page controller.
  # Shows overview statistics for the tenant.
  #
  class HomeController < ApplicationController
    ALLOWED_PERIODS = [ 7, 30, 90 ].freeze

    # GET /
    # GET /?period=7|30|90|all
    def show
      @period = parse_period(params[:period])
      @stats = DashboardStatsService.new(current_tenant, period: @period).call
    end

    private

    def parse_period(param)
      return nil if param == 'all'

      period = param&.to_i
      ALLOWED_PERIODS.include?(period) ? period : 7
    end
  end
end
