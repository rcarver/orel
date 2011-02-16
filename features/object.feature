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
      user = User.new :first_name => "Joe", :last_name => "Smith"
      puts user.first_name
      puts user.last_name
      user.first_name = "John"
      puts user.first_name
      """
    Then the output should contain:
      """
      Joe
      Smith
      John
      """


