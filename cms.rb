# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'

get '/' do
  directory = Dir.getwd + '/data'
  @files = Dir.entries(directory).reject { |file| Dir.exist?(file) }
  erb(:index)
end
