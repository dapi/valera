# frozen_string_literal: true

# Service for sending welcome messages to new Telegram users
class SystemPromptService
  def self.system_prompt
    ApplicationConfig.system_prompt
                     .gsub(/{{\s*COMPANY_INFO\s*}}/, ApplicationConfig.company_info)
                     .gsub(/{{\s*PRICE_LIST\s*}}/, ApplicationConfig.price_list)

    # Антропик просит в system mesage добавлять, то попробуем пока так
    # .gsub(/{TOOLS_INSTRUCTION}/, ApplicationConfig.tools_instruction)
  end
end
