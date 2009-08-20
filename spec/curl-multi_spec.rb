# curl-multi - Ruby bindings for the libcurl multi interface
# Copyright (C) 2007 Philotic, Inc.

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require File.dirname(__FILE__) + '/spec_helper.rb'

describe 'Curl::Multi' do
  before(:all) do
    puts "setting up server\n"
    @port = 9192
    @server_process = Process.fork do
      $stdout.reopen('log/test_server.stdout', 'w')
      $stderr.reopen('log/test_server.stderr', 'w')
      CurlTestServer.run! :host => 'localhost', :port => @port
    end
    @server = "http://localhost:#{@port}"
    sleep(1) #give server time to boot
  end

  before(:each) do
    @curl_multi = Curl::Multi.new
  end

  after(:all) do
    puts "\nTearing down server"
    @curl_multi.post("#{@server}/flush", {}, lambda {}, lambda {})
    @curl_multi.select([], []) while @curl_multi.size > 0
    Process.kill('KILL', @server_process)
  end

  it "Should be able to get one ok" do
    c = Curl::Multi.new()
    success = lambda do |body|
      body.should eql('ok')
    end
    failure = lambda do |ex|
      fail ex
    end
    c.get("#{@server}/ok", success, failure)
    c.select([], []) while c.size > 0
  end
end
