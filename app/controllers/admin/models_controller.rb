# frozen_string_literal: true

module Admin
  # Read-only resource for viewing AI models managed by ruby_llm.
  # Only index and show actions are available (routes restrict to only: [:index, :show]).
  # Models are automatically synced by ruby_llm gem.
  #
  # Supports filtering via URL parameters:
  #   ?provider=openai - filter by provider
  #   ?family=gpt      - filter by model family
  #   ?name=GPT        - filter by name (ILIKE search)
  class ModelsController < Admin::ApplicationController
    before_action :authorize_superuser!

    private

    def scoped_resource
      resources = resource_class.all
      resources = apply_collection_filters(resources)
      resources
    end

    def apply_collection_filters(resources)
      dashboard_class::COLLECTION_FILTERS.each do |filter_name, filter_proc|
        filter_value = params[filter_name]
        next if filter_value.blank?

        resources = filter_proc.call(resources, filter_value)
      end
      resources
    end

    def dashboard_class
      ModelDashboard
    end
  end
end
