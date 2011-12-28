When /^I run some Orel code:$/ do |string|
  step %{a file named "runner.rb" with:}, <<-EOF
    require 'orel/test'
    require 'classes'
    Orel.recreate_database!
    Orel.create_tables!
    #{string}
    puts "done running code"
  EOF
  step %{I run `ruby -I ../lib runner.rb`}
  step %{the output should contain:}, "done running code"
end

