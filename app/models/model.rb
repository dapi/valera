# frozen_string_literal: true

# Read-only view of the RubyLLM model registry (table ruby_llm_models).
#
# RubyLLM 2.0 owns the registry records (RubyLLM.models); this class only backs
# the admin dashboard. Do not add acts_as_model or write through it.
class Model < ApplicationRecord
  self.table_name = 'ruby_llm_models'

  def readonly?
    true
  end
end
