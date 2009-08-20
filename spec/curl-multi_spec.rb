# curl-multi - Ruby bindings for the libcurl multi interface # Copyright (C) 2007 Philotic, Inc.

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

describe 'Curl::Multi with a single request' do
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
    success = lambda do |body|
      body.should eql('ok')
    end
    failure = lambda do |ex|
      fail ex
    end
    @curl_multi.get("#{@server}/ok", success, failure)
    @curl_multi.select([], []) while @curl_multi.size > 0
  end

  it "Should be able to handle errors" do
    success = lambda do |body|
      fail(body)
    end
    failure = lambda do |ex|
      ex.should be_a Curl::HTTPError
      ex.status.should eql 500
    end
    @curl_multi.get("#{@server}/error", success, failure)
    @curl_multi.select([], []) while @curl_multi.size > 0
  end

  it "Should be able to handle redirects" do
    success = lambda do |body|
      fail(body)
    end
    failure = lambda do |ex|
      ex.should be_a Curl::HTTPError
      ex.status.should eql 302
    end
    @curl_multi.get("#{@server}/redirect/ok", success, failure)
    @curl_multi.select([], []) while @curl_multi.size > 0
  end
end
describe 'Curl::Multi with many connections' do
  before(:all) do
    puts "setting up multiple servers for many connection test\n"
    @ports = (9100...9120)
    @servers = []
    @server_processes = []
    @ports.each do |port|
      process = Process.fork do
        $stdout.reopen('/dev/null', 'w')
        $stderr.reopen('/dev/null', 'w')
        puts "trying to open #{port}"
        CurlTestServer.run! :host => 'localhost', :port => port
      end
      @server_processes.push process
      @servers.push "http://localhost:#{port}"
      sleep(0.1)
    end
    #sleep(1) #give servers time to boot
  end

  after(:all) do
    puts "\nTearing down servers"
    @server_processes.each do |pid|
      Process.kill('KILL', pid)
    end
  end

  before(:each) do
    @curl_multi = Curl::Multi.new
  end

  it "should be able to get 600 oks" do
    num_oks = 0
    success = lambda do |body|
      body.should eql('ok')
      num_oks += 1
    end
    failure = lambda do |ex|
      fail ex
    end
    #start with a sleep to get everybody queued
    @servers.each do |server|
      @curl_multi.get("#{server}/sleep/1", lambda {}, failure)
    end
    30.times do
      @servers.each do |server|
        @curl_multi.get("#{server}/ok", success, failure)
      end
    end
    @curl_multi.select([], []) while @curl_multi.size > 0
    num_oks.should eql 600
    @curl_multi.size.should eql(0)
  end
  it "should be able to get 300 oks and 300 fails" do
    num_oks = 0
    num_errors = 0
    success = lambda do |body|
      body.should eql('ok')
      num_oks += 1
    end
    failure = lambda do |ex|
      ex.should be_a Curl::HTTPError
      ex.status.should eql 500
      num_errors += 1
    end
    #start with a sleep to get everybody queued
    @servers.each do |server|
      @curl_multi.get("#{server}/sleep/1", lambda {}, lambda {})
    end
    15.times do
      @servers.each do |server|
        @curl_multi.get("#{server}/ok", success, failure)
        @curl_multi.get("#{server}/error", success, failure)
      end
    end
    @curl_multi.select([], []) while @curl_multi.size > 0
    num_oks.should eql 300
    num_errors.should eql 300
    @curl_multi.size.should eql(0)
  end
end
