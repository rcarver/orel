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
      puts user[:last_name]
      user.first_name = "Bob"
      user[:last_name] = "Johnson"
      puts user.first_name
      puts user[:last_name]
      """
    Then the output should contain:
      """
      John
      Smith
      Bob
      Johnson
      """

  Scenario: Create a record with a surrogate key
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
      Orel::Test.show "SELECT id, first_name, last_name from users"
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
      user = User.create :first_name => "John", :last_name => "Smith", :age => 10
      user.save
      Orel::Test.show "SELECT first_name, last_name, age from users"
      """
    Then the output should contain:
      """
      ---
      John,Smith,10
      ---
      """

  Scenario: Create a referenced (one-to-many) relationship using surrogate keys
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
      class Thing
        include Orel::Object
        heading do
          key { id }
          ref User
          att :id, Orel::Domains::Serial
          att :name, Orel::Domains::String
        end
      end
      """
    When I run some Orel code:
      """
      user = User.create :first_name => "John", :last_name => "Smith"
      thing = Thing.new User => user, :name => "box"
      thing.save
      Orel::Test.show <<-SQL
        SELECT users.id, users.first_name, users.last_name, things.id, things.user_id, things.name
        FROM users, things
        WHERE users.id = things.user_id
      SQL
      """
    Then the output should contain:
      """
      ---
      1,John,Smith,1,1,box
      ---
      """

  Scenario: Create a referenced (one-to-many) relationship using natural keys
    Given I have these class definitions:
      """
      class User
        include Orel::Object
        heading do
          key { first_name / last_name }
          att :first_name, Orel::Domains::String
          att :last_name, Orel::Domains::String
        end
      end
      class Thing
        include Orel::Object
        heading do
          key { User / name }
          ref User
          att :name, Orel::Domains::String
        end
      end
      """
    When I run some Orel code:
      """
      user = User.create :first_name => "John", :last_name => "Smith"
      thing = Thing.new User => user, :name => "box"
      thing.save
      Orel::Test.show <<-SQL
        SELECT users.first_name, users.last_name, things.name
        FROM users, things
        WHERE users.first_name = things.first_name and users.last_name = things.last_name
      SQL
      """
    Then the output should contain:
      """
      ---
      John,Smith,box
      ---
      """

  Scenario: Update a record with a surrogate key
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
      user = User.create :first_name => "Mary", :last_name => "White"
      user = User.create :first_name => "John", :last_name => "Smith"
      puts user.id.inspect
      user.first_name = "Bob"
      user.save
      puts user.id.inspect
      Orel::Test.show "SELECT id, first_name, last_name FROM users ORDER BY first_name"
      """
    Then the output should contain:
      """
      2
      2
      ---
      2,Bob,Smith
      1,Mary,White
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
      user = User.create :first_name => "Mary", :last_name => "White", :age => 10
      user = User.create :first_name => "John", :last_name => "Smith", :age => 10
      Orel::Test.show "SELECT first_name, last_name, age FROM users ORDER BY first_name ASC"
      user.age = 30
      user.save
      Orel::Test.show "SELECT first_name, last_name, age FROM users ORDER BY first_name ASC"
      """
    Then the output should contain:
      """
      ---
      John,Smith,10
      Mary,White,10
      ---
      ---
      John,Smith,30
      Mary,White,10
      ---
      """

  Scenario: Update a record with a natural key, changing a key attribute
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
      user = User.create :first_name => "Mary", :last_name => "White", :age => 10
      user = User.create :first_name => "John", :last_name => "Smith", :age => 10
      Orel::Test.show "SELECT first_name, last_name, age FROM users ORDER BY first_name ASC"
      user.first_name = "Bob"
      user.save
      Orel::Test.show "SELECT first_name, last_name, age FROM users ORDER BY first_name ASC"
      """
    Then the output should contain:
      """
      ---
      John,Smith,10
      Mary,White,10
      ---
      ---
      Bob,Smith,10
      Mary,White,10
      ---
      """

  Scenario: Destroy a record with a surrogate key
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
      user = User.create :first_name => "Mary", :last_name => "White"
      user = User.create :first_name => "John", :last_name => "Smith"
      Orel::Test.show "SELECT id, first_name, last_name FROM users ORDER BY first_name ASC"
      user.destroy
      Orel::Test.show "SELECT id, first_name, last_name FROM users ORDER BY first_name ASC"
      """
    Then the output should contain:
      """
      ---
      2,John,Smith
      1,Mary,White
      ---
      ---
      1,Mary,White
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
      user = User.create :first_name => "Mary", :last_name => "White", :age => 10
      user = User.create :first_name => "John", :last_name => "Smith", :age => 10
      Orel::Test.show "SELECT first_name, last_name, age from users"
      user.destroy
      Orel::Test.show "SELECT first_name, last_name, age from users"
      """
    Then the output should contain:
      """
      ---
      John,Smith,10
      Mary,White,10
      ---
      ---
      Mary,White,10
      ---
      """

