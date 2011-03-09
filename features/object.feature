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
      user = User.create :first_name => "John", :last_name => "Smith", :age => 10
      user.save
      Orel::Test.show "SELECT first_name, last_name, age from user"
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
        SELECT user.id, user.first_name, user.last_name, thing.id, thing.user_id, thing.name
        FROM user, thing
        WHERE user.id = thing.user_id
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
        SELECT user.first_name, user.last_name, thing.name
        FROM user, thing
        WHERE user.first_name = thing.first_name and user.last_name = thing.last_name
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
      Orel::Test.show "SELECT id, first_name, last_name FROM user ORDER BY first_name"
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
      Orel::Test.show "SELECT first_name, last_name, age FROM user ORDER BY first_name ASC"
      user.age = 30
      user.save
      Orel::Test.show "SELECT first_name, last_name, age FROM user ORDER BY first_name ASC"
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
      Orel::Test.show "SELECT first_name, last_name, age FROM user ORDER BY first_name ASC"
      user.first_name = "Bob"
      user.save
      Orel::Test.show "SELECT first_name, last_name, age FROM user ORDER BY first_name ASC"
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
      Orel::Test.show "SELECT id, first_name, last_name FROM user ORDER BY first_name ASC"
      user.destroy
      Orel::Test.show "SELECT id, first_name, last_name FROM user ORDER BY first_name ASC"
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
      Orel::Test.show "SELECT first_name, last_name, age from user"
      user.destroy
      Orel::Test.show "SELECT first_name, last_name, age from user"
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



