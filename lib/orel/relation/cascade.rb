module Orel
  module Relation
    class Cascade < Struct.new(:on_delete, :on_update)

      RESTRICT = 'NO ACTION'
      CASCADE  = 'CASCADE'

    end
  end
end
