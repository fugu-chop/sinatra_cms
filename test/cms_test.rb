# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require 'fileutils'
require_relative '../cms'

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    # This method is accessible through the require_relative, and defined in the global scope
    FileUtils.mkdir_p(data_path)
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def create_document(name, content = '')
    File.open(File.join(data_path, name), 'w') do |file|
      file.write(content)
    end
  end

  def generate_code(number)
    charset = ('a'..'z').to_a
    Array.new(number) { charset.sample }.join
  end

  def test_index
    create_document('about.md')
    create_document('changes.txt')

    get '/'

    assert_equal(200, last_response.status)
    assert_equal('text/html;charset=utf-8', last_response['Content-Type'])
    assert_includes(last_response.body, 'about.md')
    assert_includes(last_response.body, 'changes.txt')
  end

  def test_viewing_text_document
    create_document('history.txt', 'Ruby 0.95 released')

    get '/history.txt'

    assert_equal(200, last_response.status)
    assert_equal('text/plain', last_response['Content-Type'])
    assert_includes(last_response.body, 'Ruby 0.95 released')
  end

  def test_invalid_file
    random_file = "#{generate_code(10)}.txt"

    get "/#{random_file}"

    assert_equal(302, last_response.status)
    # Request the page that the user was redirected to
    get last_response['Location']
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "#{random_file} does not exist")

    get '/'
    refute_includes(last_response.body, "#{random_file} does not exist")
  end

  def test_markdown
    create_document('about.md', '<h1>Ruby is...</h1>')

    get '/about.md'

    assert_equal(200, last_response.status)
    assert_equal('text/html;charset=utf-8', last_response['Content-Type'])
    assert_includes(last_response.body, '<h1>Ruby is...</h1>')
  end

  def test_edit_view
    create_document('history.txt', '1993 - Yukihiro')

    get '/history.txt/edit'

    assert_equal(200, last_response.status)
    assert_equal('text/html;charset=utf-8', last_response['Content-Type'])
    assert_includes(last_response.body, '1993 - Yukihiro')
    assert_includes(last_response.body, '<textarea')
    assert_includes(last_response.body, '<button type="submit"')
  end

  def test_edit_functionality
    create_document('changes.txt')

    # The param name comes from the id of the element
    post '/changes.txt/edit', content: 'new content'

    # When testing, a redirection executed through Rack::Test will set a 302 regardless of request type
    # If you redirect in Sinatra from a POST route, the response will return a 303 status code
    # If you redirect in Sinatra from a GET route, then the response will return a 302
    assert_equal(302, last_response.status)

    get last_response['Location']
    assert_includes(last_response.body, 'changes.txt has been updated')

    get '/changes.txt'
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'new content')
  end

  def test_view_new_document_form
    get "/new"

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "<input")
    # The q( syntax is necessary as single quotes don't play well with tags
    assert_includes(last_response.body, %q(<button type='submit'))
  end


  def test_create_new_document
    post "/new", new_doc: "test.txt"
    assert_equal(302, last_response.status)

    get last_response["Location"]
    assert_includes(last_response.body, "test.txt was created")

    get "/"
    assert_includes(last_response.body, "test.txt")
  end

  def test_create_new_document_without_filename
    post "/new", new_doc: ""
    assert_equal(422, last_response.status)
    assert_includes(last_response.body, "A name is required")
  end
end
