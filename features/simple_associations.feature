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
          SELECT user.id, user.first_name, user.last_name, user_status.value
          FROM user, user_status
          WHERE user.id = user_status.user_id
        SQL
      end
      user = User.create :first_name => "John", :last_name => "Smith"
      user[:status] = { :value => "ok" }
      user.save
      show
      user[:status] = { :value => "changed" }
      user.save
      show
      """
    Then the output should contain:
      """
      ---
      1,John,Smith,ok
      ---
      ---
      1,John,Smith,changed
      ---
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
          SELECT user.id, user.first_name, user.last_name, user_logins.ip
          FROM user, user_logins
          WHERE user.id = user_logins.user_id
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
      """

