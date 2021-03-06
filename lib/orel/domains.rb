module Orel
  module Domains

    class Domain
      # TODO: use better terms
      def encode(value)
        value
      end
      def decode(value)
        value
      end
      # Public: Can this type be inserted?
      #
      # Returns a Boolean.
      def insertable?
        true
      end
      # TODO: validations, etc
    end

    class Serial < Domain
      def type_def
        "INT(11) NOT NULL AUTO_INCREMENT"
      end
      def for_foreign_key
        Integer.new
      end
      def insertable?
        false
      end
    end

    class Boolean < Domain
      def type_def
        "TINYINT(1) NOT NULL"
      end
    end

    class String < Domain
      def type_def
        "VARCHAR(255) NOT NULL"
      end
      def for_foreign_key
        self
      end
    end

    class Text < Domain
      def type_def
        "TEXT NOT NULL"
      end
    end

    class Integer < Domain
      def type_def
        "INT(11) NOT NULL"
      end
      def for_foreign_key
        self
      end
    end

    class BigInt < Domain
      def type_def
        "BIGINT NOT NULL"
      end
      def for_foreign_key
        self
      end
    end

    class Float < Domain
      def type_def
        "FLOAT(11) NOT NULL"
      end
    end

    class DateTime < Domain
      def type_def
        "DATETIME NOT NULL"
      end
    end

    class Date < Domain
      def type_def
        "DATE NOT NULL"
      end
    end

  end
end
