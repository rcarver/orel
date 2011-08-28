module UsersAndThings
  def self.table_name_prefix
    'users_and_things_'
  end

  class User
    include Orel::Object
    heading do
      key { first_name / last_name }
      att :first_name, Orel::Domains::String
      att :last_name, Orel::Domains::String
      att :age, Orel::Domains::Integer
    end
    # 1:1 simple association
    heading :status do
      key { UsersAndThings::User }
      att :value, Orel::Domains::String
    end
    # M:1 simple associations
    heading :ips do
      key { UsersAndThings::User / ip }
      att :ip, Orel::Domains::String
    end
  end

  class Thing
    include Orel::Object
    heading do
      key { id }
      att :id, Orel::Domains::Serial
      att :name, Orel::Domains::String
      ref User
    end
  end
end
