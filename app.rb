require 'sinatra'
require 'sinatra/reloader' if development?
require 'dotenv'
require './ramesh'

Dotenv.load

CACHE_MAX_AGE = 10 * 24 * 60 * 60 # 10 days



def now
  Time.now.tap{|t| break "#{t.strftime('%Y%m%d%H')}#{t.min - (t.min % 5) - 5}" }
end

def valid_time?(t)
  @valid_time ||= Ramesh::Client.new.send(:meshes_index)
  @valid_time.include?(t)
end

def valid_format?(f)
  %w(jpg).include?(f)
end

error 403 do
  "Access forbidden\n"
end

error 404 do
  "Not Found\n"
end

get '/' do
  'index'
end

get '/current.:format' do
  redirect "/d/#{now}.#{params[:format]}", 303
end

get '/d/:time.:format' do
  t = params[:time]
  f = params[:format]
  return 404 unless valid_format?(f)
  return 404 unless valid_time?(t)

  cache_control :public, max_age: CACHE_MAX_AGE
  content_type 'image/jpeg'
  Ramesh::Image.new(t).to_blob
end
