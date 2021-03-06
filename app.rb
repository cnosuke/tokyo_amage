require 'sinatra'
require 'sinatra/reloader' if development?
require './ramesh'
require 'dalli'

CACHE_MAX_AGE = 12 * 60 * 60 # 12 hours
VALID_TIME_CACHE_KEY = 'valid_time_list'

def cache
  @cache ||= Dalli::Client.new('127.0.0.1:11211')
end

def time_to_s(now)
  (now - (1*60)).tap{|t| break "#{t.strftime('%Y%m%d%H')}#{sprintf('%02d',(t.min - (t.min % 5)))}" }
end

def now
  time_to_s(Time.now)
end

def now_before_5min
  time_to_s(Time.now - 5*60)
end

def valid_time?(t)
  valid_time_list = cache.get(VALID_TIME_CACHE_KEY)
  unless valid_time_list
    valid_time_list = Ramesh::Client.new.send(:meshes_index)
    cache.set(VALID_TIME_CACHE_KEY, valid_time_list, 3 * 60) # 3 mins
  end

  valid_time_list.include?(t)
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
  haml :index
end

get '/current' do
  if valid_time?(now)
    redirect "/d/#{now}.jpg", 302
  else
    redirect "/d/#{now_before_5min}.jpg", 302
  end
end

get '/tokyo23/current' do
  if valid_time?(now)
    redirect "/tokyo23/#{now}.jpg", 302
  else
    redirect "/tokyo23/#{now_before_5min}.jpg", 302
  end
end

put '/healthcheck' do
  'OK'
end

get '/d/:time.:format' do
  t = params[:time]
  f = params[:format]
  return 404 unless valid_format?(f)
  return 404 unless valid_time?(t)

  fname = "#{t}.#{f}"
  img = cache.get(fname)
  unless img
    img = Ramesh::Image.new(t).to_blob
    cache.set(fname, img, CACHE_MAX_AGE)
    GC.start
  end

  cache_control :public, max_age: CACHE_MAX_AGE
  content_type 'image/jpeg'
  img
end

get '/tokyo23/:time.:format' do
  t = params[:time]
  f = params[:format]
  return 404 unless valid_format?(f)
  return 404 unless valid_time?(t)

  fname = "tokyo23.#{t}.#{f}"
  img = cache.get(fname)
  unless img
    img = Ramesh::Image.new(t, :large).scope_to_tokyo23.to_blob
    cache.set(fname, img, CACHE_MAX_AGE)
    GC.start
  end

  cache_control :public, max_age: CACHE_MAX_AGE
  content_type 'image/jpeg'
  img
end
