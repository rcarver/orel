require 'orel'
require 'rspec'
require 'rspec/its'
require 'database_cleaner'
require 'fileutils'

OREL_LOG_FILE = File.dirname(__FILE__) + "/../log/test.log"

FileUtils.mkdir_p File.dirname(OREL_LOG_FILE)
Orel.logger = Logger.new(OREL_LOG_FILE)
Orel.logger.info "\n\nBeginning test #{Time.now}\n"

ActiveRecord::Base.establish_connection(
  :adapter => 'mysql2',
  :database => 'orel_test',
  :username => 'root'
)

require 'fixtures/users_and_things'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
  config.mock_with :rspec do |mocks|
    mocks.syntax = :should
  end
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
