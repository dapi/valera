# frozen_string_literal: true

# Fallback models for the assistant chat.
#
# The primary model may be a LiteLLM subscription alias: a single CLIProxyAPI
# replica and an OAuth session that can expire. When it fails with a transient
# or authorization error, RubyLLM retries the same request on the fallback
# (for example DeepSeek directly), so clients keep getting answers.
#
# @example
#   chat.with_fallbacks(*LlmFallbacks.models, on: LlmFallbacks::ERRORS)
module LlmFallbacks
  # Errors that switch to the fallback: RubyLLM defaults plus authorization
  # failures of an expired subscription session.
  ERRORS = [
    *RubyLLM::Fallback::DEFAULT_ERRORS,
    RubyLLM::UnauthorizedError,
    RubyLLM::ForbiddenError,
    RubyLLM::PaymentRequiredError
  ].freeze

  module_function

  # @return [Array<RubyLLM::Model>] fallback models in order, empty when not configured
  def models
    model_id = ApplicationConfig.llm_fallback_model.presence
    provider = ApplicationConfig.llm_fallback_provider.presence
    return [] unless model_id && provider

    [ find_model(model_id, provider) ]
  end

  def find_model(model_id, provider)
    RubyLLM.models.find(model_id, provider: provider)
  rescue RubyLLM::ModelNotFoundError
    RubyLLM::Model.default(model_id, provider)
  end
end
