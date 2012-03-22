class DailyAccumulation
  extend Orel::Sharding
  heading do
    key { day / thing }
    att :day, Orel::Domains::String
    att :thing, Orel::Domains::String
    att :count, Orel::Domains::Integer
  end
  shard_table_on(:day) do |day|
    day[0, 6]
  end
end
