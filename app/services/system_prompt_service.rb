# frozen_string_literal: true

# Сервис для управления системными инструкциями AI
#
# Формирует системный промпт для AI ассистента, подставляя в шаблон
# актуальную информацию о компании и прайс-лист.
#
# В multi-tenant режиме использует данные из Current.tenant,
# с fallback на глобальные настройки из ApplicationConfig.
#
# @example Получение системного промпта для текущего тенанта
#   Current.tenant = tenant
#   prompt = SystemPromptService.system_prompt
#   #=> "Ты AI ассистент автосервиса 'Валера'..."
#
# @example Получение промпта без тенанта (fallback)
#   Current.tenant = nil
#   prompt = SystemPromptService.system_prompt
#   #=> Использует ApplicationConfig
#
# @see ApplicationConfig для настроек промпта
# @see Current для multi-tenancy контекста
# @author Danil Pismenny
# @since 0.1.0
class SystemPromptService
  # Возвращает системный промпт с подставленными данными
  #
  # Заменяет плейсхолдеры в шаблоне промпта актуальными данными:
  # - {{COMPANY_INFO}} -> информация о компании
  # - {{PRICE_LIST}} -> прайс-лист услуг
  # - {{CURRENT_TIME}} -> текущее время
  #
  # @return [String] готовый системный промпт для AI
  # @example
  #   prompt = SystemPromptService.system_prompt
  #   #=> "Ты AI ассистент автосервиса 'Валера'..."
  # @note Результат используется для инициализации AI чата
  def self.system_prompt
    current_time = Time.current.in_time_zone.strftime('%d.%m.%Y %H:%M (%Z)')

    base_prompt
      .gsub(/{{\s*COMPANY_INFO\s*}}/, company_info)
      .gsub(/{{\s*PRICE_LIST\s*}}/, price_list)
      .gsub(/{{\s*CURRENT_TIME\s*}}/, current_time)
  end

  # Возвращает базовый шаблон системного промпта
  #
  # Приоритет: Current.tenant.system_prompt -> ApplicationConfig.system_prompt
  #
  # @return [String] шаблон системного промпта
  # @api private
  def self.base_prompt
    tenant_prompt = Current.tenant&.system_prompt
    return tenant_prompt if tenant_prompt.present?

    ApplicationConfig.system_prompt
  end
  private_class_method :base_prompt

  # Возвращает информацию о компании
  #
  # Приоритет: Current.tenant.company_info -> ApplicationConfig.company_info
  #
  # @return [String] информация о компании
  # @api private
  def self.company_info
    tenant_info = Current.tenant&.company_info
    return tenant_info if tenant_info.present?

    ApplicationConfig.company_info
  end
  private_class_method :company_info

  # Возвращает прайс-лист услуг
  #
  # Приоритет: Current.tenant.price_list -> ApplicationConfig.price_list
  #
  # @return [String] прайс-лист услуг
  # @api private
  def self.price_list
    tenant_price_list = Current.tenant&.price_list
    return tenant_price_list if tenant_price_list.present?

    ApplicationConfig.price_list
  end
  private_class_method :price_list
end
