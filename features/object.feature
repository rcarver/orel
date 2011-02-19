@object
Feature: Use the objects that back relations.

  Scenario: Read and write basic attributes
    Given I have these class definitions:
      """
      class User
        include Orel::Object
        heading do
          att :first_name, Orel::Domains::String
          att :last_name, Orel::Domains::String
        end
      end
      """
    When I run some Orel code:
      """
      user = User.new :first_name => "John", :last_name => "Smith"
      puts user.first_name
      puts user.last_name
      user.first_name = "John"
      puts user.first_name
      """
    Then the output should contain:
      """
      John
      Smith
      John
      """

  Scenario: Create a record with a serial key
    Given I have these class definitions:
      """
      class User
        include Orel::Object
        heading do
          key { id }
          att :id, Orel::Domains::Serial
          att :first_name, Orel::Domains::String
          att :last_name, Orel::Domains::String
        end
      end
      """
    When I run some Orel code:
      """
      user = User.new :first_name => "John", :last_name => "Smith"
      user.save
      puts user.id.inspect
      Orel::Test.show "SELECT id, first_name, last_name from user"
      """
    Then the output should contain:
      """
      1
      ---
      1,John,Smith
      ---
      """

  Scenario: Create a record with a natural key
    Given I have these class definitions:
      """
      class User
        include Orel::Object
        heading do
          key { first_name / last_name }
          att :first_name, Orel::Domains::String
          att :last_name, Orel::Domains::String
          att :age, Orel::Domains::Integer
        end
      end
      """
    When I run some Orel code:
      """
      user = User.new :first_name => "John", :last_name => "Smith", :age => 10
      user.save
      Orel::Test.show "SELECT first_name, last_name, age from user"
      """
    Then the output should contain:
      """
      ---
      John,Smith,10
      ---
      """

  Scenario: Update a record with a serial key
    Given I have these class definitions:
      """
      class User
        include Orel::Object
        heading do
          key { id }
          att :id, Orel::Domains::Serial
          att :first_name, Orel::Domains::String
          att :last_name, Orel::Domains::String
        end
      end
      """
    When I run some Orel code:
      """
      user = User.new :first_name => "John", :last_name => "Smith"
      user.save
      puts user.id.inspect
      user.first_name = "John"
      user.save
      puts user.id.inspect
      Orel::Test.show "SELECT id, first_name, last_name from user"
      """
    Then the output should contain:
      """
      1
      1
      ---
      1,John,Smith
      ---
      """

  Scenario: Update a record with a natural key
    Given I have these class definitions:
      """
      class User
        include Orel::Object
        heading do
          key { first_name / last_name }
          att :first_name, Orel::Domains::String
          att :last_name, Orel::Domains::String
          att :age, Orel::Domains::Integer
        end
      end
      """
    When I run some Orel code:
      """
      user = User.new :first_name => "John", :last_name => "Smith", :age => 10
      user.save
      user.age = 30
      user.save
      Orel::Test.show "SELECT first_name, last_name, age from user"
      """
    Then the output should contain:
      """
      ---
      John,Smith,30
      ---
      """

  Scenario: Destroy a record with a serial key
    Given I have these class definitions:
      """
      class User
        include Orel::Object
        heading do
          key { id }
          att :id, Orel::Domains::Serial
          att :first_name, Orel::Domains::String
          att :last_name, Orel::Domains::String
        end
      end
      """
    When I run some Orel code:
      """
      user = User.new :first_name => "John", :last_name => "Smith"
      user.save
      user.destroy
      Orel::Test.show "SELECT id, first_name, last_name from user"
      """
    Then the output should contain:
      """
      ---
      ---
      """

  Scenario: Destroy a record with a natural key
    Given I have these class definitions:
      """
      class User
        include Orel::Object
        heading do
          key { first_name / last_name }
          att :first_name, Orel::Domains::String
          att :last_name, Orel::Domains::String
          att :age, Orel::Domains::Integer
        end
      end
      """
    When I run some Orel code:
      """
      user = User.new :first_name => "John", :last_name => "Smith", :age => 10
      user.save
      user.destroy
      Orel::Test.show "SELECT first_name, last_name, age from user"
      """
    Then the output should contain:
      """
      ---
      ---
      """



