require 'orel'
require 'rspec'
require 'database_cleaner'

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

require 'fixtures/users_and_things'

RSpec.configure do |config|
  config.before(:suite) do
    Orel.finalize!
    Orel.recreate_database!
    Orel.create_tables!
    DatabaseCleaner.strategy = :transaction
  end
  config.before(:each) do
    DatabaseCleaner.start
  end
  config.after(:each) do
    DatabaseCleaner.clean
  end
end
