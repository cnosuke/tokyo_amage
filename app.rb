require 'sinatra'
require "sinatra/reloader" if development?
require 'dotenv'
Dotenv.load

error 403 do
  "Access forbidden\n"
end

get '/' do
  'index'
end
