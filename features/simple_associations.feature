Feature: Classes can define more than one relation

  Scenario: Store data in a simple one-to-one relation
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
        heading :status do
          key { User }
          att :value, Orel::Domains::String
        end
      end
      """
    When I run some Orel code:
      """
      def show
        Orel::Test.show <<-SQL
          SELECT users.id, users.first_name, users.last_name, user_status.value
          FROM users, user_status
          WHERE users.id = user_status.user_id
        SQL
      end
      user = User.create :first_name => "John", :last_name => "Smith"
      user[:status] = { :value => "ok" }
      user.save
      show
      user[:status] = { :value => "changed" }
      user.save
      show
      puts user[:status].value.inspect
      """
    Then the output should contain:
      """
      ---
      1,John,Smith,ok
      ---
      ---
      1,John,Smith,changed
      ---
      "changed"
      """

  Scenario: Store data in a simple one-to-many relation
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
        heading :logins do
          key { User / ip }
          att :ip, Orel::Domains::String
        end
      end
      """
    When I run some Orel code:
      """
      def show
        Orel::Test.show <<-SQL
          SELECT users.id, users.first_name, users.last_name, user_logins.ip
          FROM users, user_logins
          WHERE users.id = user_logins.user_id
        SQL
      end
      user = User.create :first_name => "John", :last_name => "Smith"
      user[:logins] << { :ip => "127.0.0.1" }
      user[:logins] << { :ip => "10.0.0.1" }
      user.save
      show
      user[:logins] << { :ip => "198.0.0.1" }
      user.save
      show
      puts user[:logins].map { |login| login.ip }.sort.inspect
      """
    Then the output should contain:
      """
      ---
      1,John,Smith,10.0.0.1
      1,John,Smith,127.0.0.1
      ---
      ---
      1,John,Smith,10.0.0.1
      1,John,Smith,127.0.0.1
      1,John,Smith,198.0.0.1
      ---
      ["10.0.0.1", "127.0.0.1", "198.0.0.1"]
      """

