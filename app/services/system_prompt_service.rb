# frozen_string_literal: true

# Сервис для управления системными инструкциями AI
#
# Формирует системный промпт для AI ассистента, подставляя в шаблон
# актуальную информацию о компании и прайс-лист.
#
# @example Получение системного промпта
#   service = SystemPromptService.new(tenant)
#   prompt = service.system_prompt
#   #=> "Ты AI ассистент автосервиса 'Валера'..."
#
# @see Tenant модель тенанта
# @author Danil Pismenny
# @since 0.1.0
class SystemPromptService
  # @param tenant [Tenant] тенант для которого формируется промпт
  # @raise [ArgumentError] если tenant не передан
  def initialize(tenant)
    raise ArgumentError, 'tenant is required' if tenant.nil?

    @tenant = tenant
  end

  # Возвращает системный промпт с подставленными данными
  #
  # Заменяет плейсхолдеры в шаблоне промпта актуальными данными:
  # - {{COMPANY_INFO}} -> информация о компании
  # - {{PRICE_LIST}} -> прайс-лист услуг
  # - {{CURRENT_TIME}} -> текущее время
  #
  # @return [String] готовый системный промпт для AI
  # @example
  #   service = SystemPromptService.new(tenant)
  #   prompt = service.system_prompt
  #   #=> "Ты AI ассистент автосервиса 'Валера'..."
  # @note Результат используется для инициализации AI чата
  def system_prompt
    current_time = Time.current.in_time_zone.strftime('%d.%m.%Y %H:%M (%Z)')

    tenant.system_prompt_or_default.to_s
      .gsub(/{{\s*COMPANY_INFO\s*}}/, tenant.company_info_or_default.to_s)
      .gsub(/{{\s*PRICE_LIST\s*}}/, tenant.price_list_or_default.to_s)
      .gsub(/{{\s*CURRENT_TIME\s*}}/, current_time)
  end

  private

  attr_reader :tenant
end
