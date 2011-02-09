Feature: Define stuff

  Scenario: Define a key
    Given a file named "agreement.rb" with:
      """
      class Agreement
        extend Orel::Relation
        heading do
          key :recipient_id, String
          key :entity_id, String
        end
      end
      """
    And a file named "sample.rb" with:
      """
      require 'orel/test'
      require 'agreement'

      Agreement.migrate
      puts Agreement.arel.columns.inspect
      """
    When I run "ruby -I ../lib sample.rb"
    Then the output should contain:
      """
      [:recipient_id, :entity_id]
      """




#class Agreement

  #heading do
    #key :id, String
    #key :recipient_id, String
    #key :entity_id, String

    #att :agreement_days, Integer

    #att :base_cost_integer, Integer
    #att :base_pageviews, Integer

    #att :overage_cost_integer, Integer
    #att :overage_pageviews, Integer

    #key(:foo) :x_id, String
    #key(:foo) :y_id, String

  #end

  ## primitive relational operators (did.93)

  #restrict :expensive do |price|
    #agreements.where(agreements[:base_cost]).gt(price.cents)
  #end

  #project :everything do
    #agreements.project(Arel.sql('*'))
  #end

  #join :entities do
    #agreements.join(entities).on(agreement[:entity_id].eq(entities[:id]))
  #end

  ## union do
  ## semidifference do

#end

