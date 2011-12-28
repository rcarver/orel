Given /^I have these class definitions:$/ do |string|
  step %{a file named "classes.rb" with:}, string
end

When /^I use Orel to fill my database with tables$/ do
  step %{a file named "create.rb" with:}, <<-EOF
    require 'orel/test'
    require 'classes'
    Orel.recreate_database!
    Orel.create_tables!
    puts "tables created!"
  EOF
  step %{I run `ruby -I ../lib create.rb`}
  step %{the output should contain:}, "tables created!"
end

Then /^my database looks like:$/ do |string|
  step %{a file named "show.rb" with:}, <<-EOF
    require 'orel/test'
    require 'classes'
    puts "begin"
    puts Orel::AR.connection.structure_dump.strip
    puts "end"
  EOF
  step %{I run `ruby -I ../lib show.rb`}
  step %{the output should contain:}, "begin\n#{string}\nend"
end

