module Orel
  module Relation
    # A foreign key describes a parent/child relationship between two headings.
    #
    # parent_heading - Heading the parent in the relationship.
    # parent_key     - Key the key in the parent heading that the child will reference.
    # child_heading  - Heading the child in the relationship.
    # child_key      - Key the key in the child heading that references the parent key.
    # cascade        - Cascade how cascaded updates and delete should behave.
    #
    ForeignKey = Struct.new(:parent_heading, :parent_key, :child_heading, :child_key, :cascade)
  end
end
