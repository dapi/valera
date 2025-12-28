# frozen_string_literal: true

# Helper methods for tenant dashboard views
module TenantsHelper
  # Generates a sortable column header link
  #
  # @param column [String] Database column name to sort by
  # @param title [String] Display title for the column header
  # @param default_direction [Symbol] Default sort direction (:asc or :desc)
  # @return [String] HTML link with sort indicators
  #
  # @example
  #   sortable_column('name', t('.headers.name'))
  #   # => <a href="?sort=name&direction=asc">Name ▲</a>
  #
  def sortable_column(column, title, default_direction: :asc)
    current_column = params[:sort]
    current_direction = params[:direction]

    # Determine next direction
    if column == current_column
      next_direction = current_direction == 'asc' ? 'desc' : 'asc'
    else
      next_direction = default_direction.to_s
    end

    # Build URL preserving other params
    url_params = request.query_parameters.merge(sort: column, direction: next_direction)

    # Build indicator
    indicator = if column == current_column
                  current_direction == 'asc' ? ' ▲' : ' ▼'
    else
                  ''
    end

    link_to(title + indicator, url_for(url_params), class: 'hover:text-gray-700 cursor-pointer')
  end

  # Masks bot token for secure display
  # Shows bot_id and first/last 2 characters of secret
  #
  # @param token [String] Telegram bot token (e.g., "123456789:ABCdefGHI...")
  # @return [String, nil] Masked token (e.g., "123456789:AB...HI") or nil if blank
  #
  # @example
  #   masked_bot_token("123456789:ABCdefGHIjklMNO")
  #   # => "123456789:AB...NO"
  #
  def masked_bot_token(token)
    return nil if token.blank?

    parts = token.split(':')
    return token if parts.length < 2 || parts[1].length < 4

    bot_id = parts[0]
    secret = parts[1]
    "#{bot_id}:#{secret[0..1]}...#{secret[-2..]}"
  end
end
