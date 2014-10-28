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
    mocks.syntax = [:should, :expect]
  end
  config.before(:suite) do
    Orel.finalize!
    begin
      # This used to work, but now mysql2 throws an error during connect if the
      # database does not exist. That means there's no way to create the db via
      # the AR connection.
      Orel.recreate_database!
    rescue => e
      STDERR.puts "Creating DB via CLI. If this fails, you may need to manually create orel_test. (#{e})"
      `echo 'create database orel_test' | mysql -uroot`
    end
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
