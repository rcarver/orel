@associations
Feature: Classes have associations with other classes

  Scenario: A many to one and one to many relationship between two classes
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
          key { name }
          att :name, Orel::Domains::String
          ref User
        end
      end
      """
    When I run some Orel code:
      """
      user = User.create :first_name => "John", :last_name => "Smith"
      thing1 = Thing.create User => user, :name => "box"
      thing2 = Thing.create User => user, :name => "toy"

      puts thing1[User].first_name
      puts user[Thing].map { |t| t.name }.sort.join(', ')
      """
    Then the output should contain:
      """
      John
      box, toy
      """

  Scenario: A many to many relationship among three classes
    Given I have these class definitions:
      """
      class Supplier
        include Orel::Object
        heading do
          key { sno }
          att :sno, Orel::Domains::String
          att :name, Orel::Domains::String
        end
      end
      class Part
        include Orel::Object
        heading do
          key { pno }
          att :pno, Orel::Domains::String
          att :name, Orel::Domains::String
        end
      end
      class Shipment
        include Orel::Object
        heading do
          key { Supplier / Part }
          ref Supplier
          ref Part
          att :qty, Orel::Domains::Integer
        end
      end
      """
    When I run some Orel code:
      """
      supplier1 = Supplier.create :sno => "a", :name => "Supplier A"
      supplier2 = Supplier.create :sno => "b", :name => "Supplier B"
      part1 = Part.create :pno => "x", :name => "Part X"
      part2 = Part.create :pno => "y", :name => "Part Y"
      Shipment.create Supplier => supplier1, Part => part1, :qty => 100
      Shipment.create Supplier => supplier1, Part => part2, :qty => 200
      Shipment.create Supplier => supplier2, Part => part1, :qty => 300
      Shipment.create Supplier => supplier2, Part => part2, :qty => 400

      [supplier1, supplier2].each { |supplier|
        puts supplier.name
        supplier[Shipment].each { |shipment|
          part = shipment[Part]
          puts [part.name, shipment.qty].join(', ')
        }
      }
      puts
      [part1, part2].each { |part|
        puts part.name
        part[Shipment].each { |shipment|
          supplier = shipment[Supplier]
          puts [supplier.name, shipment.qty].join(', ')
        }
      }
      """
    Then the output should contain:
      """
      Supplier A
      Part X, 100
      Part Y, 200
      Supplier B
      Part X, 300
      Part Y, 400

      Part X
      Supplier A, 100
      Supplier B, 300
      Part Y
      Supplier A, 200
      Supplier B, 400
      """

