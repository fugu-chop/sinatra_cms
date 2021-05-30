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
  headers["Content-Type"] = "text/plain"
  content
end

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
  return load_file_content("data/#{file_name}") if File.exist?("data/#{file_name}")

  session[:error] = "#{file_name} does not exist"
  redirect "/"
end

get "/:file/edit" do
  file_name = params[:file]
  file_path = "#{root}/data/#{file_name}"
  @content = File.read(file_path)

  erb(:edit)
end
