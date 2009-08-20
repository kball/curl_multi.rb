require 'rubygems'
require 'sinatra/base'

class CurlTestServer < Sinatra::Base
  get '/sleep/:time' do
    sleep(params[:time].to_f)
    "ok"
  end
  
  get '/ok' do
    "ok"
  end
  
  get '/error' do
    raise
  end

  get '/redirect/:dest' do
    redirect params[:dest]
  end
  post '/flush' do
    $stdout.flush
    $stderr.flush
    'ok'
  end
end
