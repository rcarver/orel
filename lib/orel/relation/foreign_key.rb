module Orel
  module Relation
    ForeignKey = Struct.new(:parent_heading, :parent_key, :child_heading, :child_key)
  end
end
