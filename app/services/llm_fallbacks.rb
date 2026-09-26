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
#       .before_fallback { |fallback| LlmFallbacks.report(fallback) }
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

  # Reports a switch to the fallback model: the primary (e.g. the subscription)
  # failed, so the fallback provider is billed and the subscription may need
  # attention (an expired OAuth session looks like an authorization error).
  #
  # @param fallback [RubyLLM::Fallback] attempt passed to Chat#before_fallback
  # @return [void]
  def report(fallback)
    context = {
      from: fallback.from&.id,
      to: fallback.to&.id,
      attempt: fallback.attempt,
      error_class: fallback.error&.class&.name
    }
    Rails.logger.warn "LLM fallback: #{context.to_json} #{fallback.error&.message}"
    return unless fallback.error

    Bugsnag.notify(fallback.error) do |report|
      report.severity = 'warning'
      report.grouping_hash = "llm-fallback-#{context[:from]}-#{context[:error_class]}"
      report.add_metadata(:llm_fallback, context)
    end
  end

  def find_model(model_id, provider)
    RubyLLM.models.find(model_id, provider: provider)
  rescue RubyLLM::ModelNotFoundError
    RubyLLM::Model.default(model_id, provider)
  end
end
