# frozen_string_literal: true

# Конфигурация тарифных планов
# Загружается из config/prices.yml (без секций окружений)
class PricingConfig < Anyway::Config
  config_name :prices
  env_prefix ''

  attr_config(
    plans: [],
    min_subscription_months: 12,
    early_termination_penalty_percent: 50
  )

  coerce_types(
    min_subscription_months: :integer,
    early_termination_penalty_percent: :integer
  )

  # Загружаем YAML напрямую без секций окружений
  on_load do
    yaml_data = YAML.load_file(Rails.root.join('config/prices.yml'))
    self.plans = yaml_data['plans'] if yaml_data['plans']
    self.min_subscription_months = yaml_data['min_subscription_months'] if yaml_data['min_subscription_months']
    self.early_termination_penalty_percent = yaml_data['early_termination_penalty_percent'] if yaml_data['early_termination_penalty_percent']
  end

  class << self
    delegate_missing_to :instance

    private

    def instance
      @instance ||= new
    end
  end
end
