# frozen_string_literal: true

module Tenants
  # Controller for handling requests to non-existent tenant subdomains.
  # Shows a friendly error page with links to main site and login.
  #
  # @example Request to unknown subdomain
  #   GET http://nonexistent.supervalera.ru/
  #   # => Renders "tenant not found" page with 404 status
  #
  class NotFoundController < ::ApplicationController
    layout 'landing'

    # Shows the "tenant not found" page.
    # Responds with 404 status to indicate the resource doesn't exist.
    #
    # @return [void]
    def show
      @subdomain = request.subdomain
      Rails.logger.info "[TenantNotFound] subdomain=#{@subdomain} ip=#{request.remote_ip}"
      render status: :not_found
    end
  end
end
