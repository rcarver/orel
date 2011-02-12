Given /^I have these class definitions:$/ do |string|
  Given %{a file named "classes.rb" with:}, string
end

When /^I use Orel to fill my database with tables$/ do
  Given %{a file named "create.rb" with:}, <<-EOF
    require 'orel/test'
    require 'classes'
    Orel.drop_tables!
    Orel.create_tables!
  EOF
  When %{I run "ruby -I ../lib create.rb"}
end

Then /^my database looks like:$/ do |string|
  Given %{a file named "show.rb" with:}, <<-EOF
    require 'orel/test'
    require 'classes'
    puts "begin"
    puts Orel.show_create_tables.join("\n\n")
    puts "end"
  EOF
  When %{I run "ruby -I ../lib show.rb"}
  Then %{the output should contain:}, "begin\n#{string}\nend"
end

