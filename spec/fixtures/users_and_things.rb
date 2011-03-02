module UsersAndThings

  class User
    include Orel::Object
    heading do
      key { first_name / last_name }
      att :first_name, Orel::Domains::String
      att :last_name, Orel::Domains::String
      att :age, Orel::Domains::Integer
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
