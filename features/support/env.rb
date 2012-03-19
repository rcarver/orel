require 'aruba/cucumber'

class Array
  def split(*args)
    self
  end
end

Before do
  @aruba_timeout_seconds = 5
end
