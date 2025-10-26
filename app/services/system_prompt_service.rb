# frozen_string_literal: true

# Сервис для управления системными инструкциями AI
#
# Формирует системный промпт для AI ассистента, подставляя в шаблон
# актуальную информацию о компании и прайс-лист.
#
# @example Получение системного промпта
#   prompt = SystemPromptService.system_prompt
#   #=> "Ты AI ассистент автосервиса 'Валера'..."
#
# @see ApplicationConfig для настроек промпта
# @author Danil Pismenny
# @since 0.1.0
class SystemPromptService
  # Возвращает системный промпт с подставленными данными
  #
  # Заменяет плейсхолдеры в шаблоне промпта актуальными данными:
  # - {{COMPANY_INFO}} -> информация о компании
  # - {{PRICE_LIST}} -> прайс-лист услуг
  #
  # @return [String] готовый системный промпт для AI
  # @example
  #   prompt = SystemPromptService.system_prompt
  #   #=> "Ты AI ассистент автосервиса 'Валера'..."
  # @note Результат используется для инициализации AI чата
  def self.system_prompt
    ApplicationConfig.system_prompt
                     .gsub(/{{\s*COMPANY_INFO\s*}}/, ApplicationConfig.company_info)
                     .gsub(/{{\s*PRICE_LIST\s*}}/, ApplicationConfig.price_list)

    # Антропик просит в system mesage добавлять, то попробуем пока так
    # .gsub(/{TOOLS_INSTRUCTION}/, ApplicationConfig.tools_instruction)
  end
end
