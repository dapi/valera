# frozen_string_literal: true

require 'administrate/field/base'

# Custom Administrate field for displaying subdomain with domain suffix
class SubdomainField < Administrate::Field::Base
  def to_s
    data
  end

  # Returns the full domain (subdomain.host)
  def full_domain
    return nil if data.blank?

    "#{data}.#{ApplicationConfig.host}"
  end

  # Returns the domain suffix (.host)
  def domain_suffix
    ".#{ApplicationConfig.host}"
  end

  # Returns the full URL
  def full_url
    return nil if data.blank?

    port = ApplicationConfig.public_port_with_default
    port_suffix = standard_port?(port) ? '' : ":#{port}"

    "#{ApplicationConfig.protocol}://#{full_domain}#{port_suffix}"
  end

  private

  def standard_port?(port)
    (port == 80 && ApplicationConfig.protocol == 'http') ||
      (port == 443 && ApplicationConfig.protocol == 'https')
  end
end
