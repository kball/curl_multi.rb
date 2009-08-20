require File.dirname(__FILE__) + '/../lib/curl-multi'
require File.dirname(__FILE__) + '/test_server.rb'
require 'spec/autorun'
require 'spork'

Spork.prefork do
  Spec::Runner.configure do |config|
    config.mock_with :mocha
  end
end

Spork.each_run do
end
