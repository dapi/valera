class Chat < ApplicationRecord
  acts_as_chat
  belongs_to :telegram_user

  # Используем дефолтную модель из ruby_llm
  def model
    Model.find_by(provider: ApplicationConfig.llm_provider, name: ApplicationConfig.llm_model)
  end
end
