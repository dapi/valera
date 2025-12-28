# frozen_string_literal: true

module Admin
  # Read-only resource for viewing AI models managed by ruby_llm.
  # Only index and show actions are available (routes restrict to only: [:index, :show]).
  # Models are automatically synced by ruby_llm gem.
  #
  # Supports filtering via URL parameters (handled by ApplicationController):
  #   ?provider=openai - filter by provider
  #   ?family=gpt      - filter by model family
  #   ?name=GPT        - filter by name (ILIKE search)
  class ModelsController < Admin::ApplicationController
    before_action :authorize_superuser!
  end
end
