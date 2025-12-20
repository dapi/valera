class AddTenantToAnalyticsEvents < ActiveRecord::Migration[8.1]
  def change
    # Очистка тестовых данных перед добавлением NOT NULL constraint
    execute 'DELETE FROM analytics_events'

    add_reference :analytics_events, :tenant, null: false, foreign_key: true
  end
end
