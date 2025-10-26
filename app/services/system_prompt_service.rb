# frozen_string_literal: true

# Service for sending welcome messages to new Telegram users
class SystemPromptService
  def self.system_prompt
    ApplicationConfig.system_prompt
      .gsub(/{COMPANY_INFO}/, ApplicationConfig.company_info)
      .gsub(/{PRICE_LIST}/, ApplicationConfig.price_list)
      .gsub(/{TOOLS_INSTRUCTION}/, ApplicationConfig.tools_instruction)
  end
end
