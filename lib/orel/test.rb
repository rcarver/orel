require 'orel'
require 'active_record'
require 'mysql2'

Arel::Table.engine = ActiveRecord::Base

ActiveRecord::Base.establish_connection(
  :adapter => 'mysql2',
  :database => 'orel_test',
  :username => 'root',
  :password => ''
)
