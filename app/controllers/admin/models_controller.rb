# frozen_string_literal: true

module Admin
  # Read-only resource for viewing AI models managed by ruby_llm.
  # Only index and show actions are available (routes restrict to only: [:index, :show]).
  # Models are automatically synced by ruby_llm gem.
  class ModelsController < Admin::ApplicationController
    before_action :authorize_superuser!
  end
end
