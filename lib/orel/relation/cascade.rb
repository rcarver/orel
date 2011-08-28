module Orel
  module Relation
    # An extension of ForeignKey to describe fk cascades.
    class Cascade < Struct.new(:on_delete, :on_update)
      RESTRICT = 'NO ACTION'
      CASCADE  = 'CASCADE'
    end
  end
end
