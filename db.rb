# frozen_string_literal: true

require 'sequel'

# Подключение к базе данных SQLite
DB = Sequel.connect('sqlite://db/test.db')

# Определение моделей
require_relative 'app/models/user'
require_relative 'app/models/template'
require_relative 'app/models/product'
require_relative 'app/models/operation'
