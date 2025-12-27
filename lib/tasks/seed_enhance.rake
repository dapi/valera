# frozen_string_literal: true

# Enhance db:seed to also load LLM models
Rake::Task['db:seed'].enhance do
  Rake::Task['ruby_llm:load_models'].invoke
end
