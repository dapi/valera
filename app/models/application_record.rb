# frozen_string_literal: true

# Абстрактный базовый класс для всех ActiveRecord моделей приложения
#
# Предоставляет общую функциональность и настройки для всех моделей системы.
# Все модели приложения должны наследоваться от этого класса.
#
# @example Создание новой модели
#   class Product < ApplicationRecord
#     # реализация модели
#   end
#
# @author Danil Pismenny
# @since 0.1.0
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end
