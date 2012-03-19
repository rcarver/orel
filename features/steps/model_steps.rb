When /^I run some Orel code:$/ do |string|
  step %{a file named "runner.rb" with:}, <<-EOF
    require 'orel/test'
    require 'classes'
    Orel.recreate_database!
    Orel.create_tables!
    begin
      #{string}
      puts "done running code"
    rescue Exception => e
      puts e.inspect
      puts e.backtrace.join("\n")
    end
  EOF
  step %{I run `ruby -I ../lib -I . runner.rb`}
  step %{the output should contain:}, "done running code"
end

