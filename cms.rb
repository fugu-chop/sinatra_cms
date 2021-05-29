# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'

# File.expand_path("..", __FILE__) represents the name of the file that contains the reference to __FILE__.
# E.g. if your file is named myprog.rb and you run it with the ruby myprog.rb, then __FILE__ is myprog.rb.
# When we combine this value with .. (the parent directory) in the call to expand_path, 
# we get the absolute path name of the directory where our program lives. Rubocop prefers File.expand_path(__dir__).
root = File.expand_path(__dir__)

get '/' do
  @files = Dir.glob("#{root}/data/*").map do |path|
    File.basename(path)
  end
  erb(:index)
end

get '/:file' do
  file_name = params[:file]
  # Headers is a hash that's available through Sinatra, just like params
  headers["Content-Type"] = "text/plain"
  File.readlines("data/#{file_name}")
end

