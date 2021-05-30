# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'dotenv/load'
require "redcarpet"

Dotenv.load

# File.expand_path("..", __FILE__) represents the name of the file that contains the reference to __FILE__.
# E.g. if your file is named myprog.rb and you run it with the ruby myprog.rb, then __FILE__ is myprog.rb.
# When we combine this value with .. (the parent directory) in the call to expand_path, 
# we get the absolute path name of the directory where our program lives. Rubocop prefers File.expand_path(__dir__).
configure do
  enable(:sessions)
  set(:session_secret, ENV['SECRET'])
end

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def load_file_content(path)
  content = File.read(path)
  return load_txt(content) if File.extname(path) == '.txt'
  render_markdown(content) if File.extname(path) == '.md'
end

def load_txt(content)
  # Headers is a hash that's available through Sinatra, just like params
  headers["Content-Type"] = "text/plain"
  content
end

def data_path
  return File.expand_path("../test/data", __FILE__) if ENV["RACK_ENV"] == "test"
  File.expand_path("../data", __FILE__)
end

get '/' do
  # The join method on file objects appends a '/' symbol between arguments (OS dependent)
  pattern = File.join(data_path, '*')
  @files = Dir.glob(pattern).map do |path|
    File.basename(path)
  end
  erb(:index)
end

get '/:file' do
  file_path = File.join(data_path, params[:file])
  file_name = params[:file]
  return load_file_content(file_path) if File.exist?(file_path)

  session[:message] = "#{file_name} does not exist"
  redirect "/"
end

get '/:file/edit' do
  file_name = params[:file]
  file_path = File.join(data_path, file_name)
  @content = File.read(file_path)

  erb(:edit)
end

post '/:file/edit' do
  file_name = params[:file]
  file_path = File.join(data_path, file_name)
  File.write(file_path , params[:content])

  session[:message] = "#{file_name} has been updated."
  redirect '/'
end
