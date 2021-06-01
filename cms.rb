# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'dotenv/load'
require 'redcarpet'

Dotenv.load

configure do
  # This enables use of the session hash
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

  erb(render_markdown(content)) if File.extname(path) == '.md'
end

def load_txt(content)
  # Headers is a hash that's available through Sinatra, just like params
  headers['Content-Type'] = 'text/plain'
  content
end

def data_path
  return File.expand_path('test/data', __dir__) if ENV['RACK_ENV'] == 'test'
  File.expand_path('data', __dir__)
end

def empty_doc_name?
  params[:new_doc].empty?
end

def validate_file_extension(file_name)
  file_name.strip!
  file_name += '.txt' if File.extname(file_name).empty?
  file_name
end

def valid_login?(username, password)
  username == ENV['USERNAME'] && password == ENV['PASSWORD']
end

def redirect_sign_in
  session[:message] = 'You must be signed in to do that.'
  redirect '/users/login'
end

get '/' do
  # The join method on file objects appends a '/' symbol between arguments (OS dependent)
  pattern = File.join(data_path, '*')
  @files = Dir.glob(pattern).map do |path|
    File.basename(path)
  end
  erb(:index)
end

get '/users/login' do
  erb(:login)
end

post '/users/login' do
  if valid_login?(params[:username], params[:password])
    session[:username] = params[:username]
    session[:login] = 'success'
    session[:message] = 'Welcome!'
    redirect '/'
  end

  session[:message] = 'Invalid Credentials'
  status 422
  erb(:login)
end

post '/users/logout' do
  session.delete(:login)
  session[:username] = nil
  session[:message] = 'You have been signed out.'
  redirect '/'
end

get '/new' do
  redirect_sign_in unless session[:login]
  erb(:new)
end

get '/:file' do
  file_path = File.join(data_path, params[:file])
  file_name = params[:file]
  return load_file_content(file_path) if File.exist?(file_path)

  session[:message] = "#{file_name} does not exist"
  redirect '/'
end

get '/:file/edit' do
  redirect_sign_in unless session[:login]
  file_name = params[:file]
  file_path = File.join(data_path, file_name)
  @content = File.read(file_path)

  erb(:edit)
end

post '/:file/edit' do
  redirect_sign_in unless session[:login]
  file_name = params[:file]
  file_path = File.join(data_path, file_name)
  File.write(file_path, params[:content])

  session[:message] = "#{file_name} has been updated."
  redirect '/'
end

post '/new' do
  redirect_sign_in unless session[:login]

  if empty_doc_name?
    session[:message] = 'A name is required'
    status 422
    return erb(:new)
  end

  file_name = validate_file_extension(params[:new_doc])
  file_path = File.join(data_path, file_name)

  File.write(file_path, '')

  session[:message] = "#{file_name} was created."
  redirect '/'
end

post '/:file/delete' do
  redirect_sign_in unless session[:login]

  file_name = params[:file]
  file_path = File.join(data_path, file_name)
  File.delete(file_path)

  session[:message] = "#{file_name} was deleted"
  redirect '/'
end
