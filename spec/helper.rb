require 'orel'
require 'rspec'

require 'active_record'
require 'mysql2'

Orel.logger = Logger.new(File.dirname(__FILE__) + "/../log/test.log")
Orel.logger.info "\n\nBeginning test #{Time.now}\n"

Arel::Table.engine = ActiveRecord::Base

ActiveRecord::Base.logger = Orel.logger
ActiveRecord::Base.establish_connection(
  :adapter => 'mysql2',
  :database => 'orel_test',
  :username => 'root',
  :password => ''
)

RSpec.configure do |config|

end
