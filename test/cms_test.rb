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

  def session
    last_request.env['rack.session']
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

  def admin_session
    { 'rack.session' => { login: 'success' } }
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
    assert_equal(session[:message], "#{random_file} does not exist")

    # Request the page that the user was redirected to
    get last_response['Location']

    assert_equal(200, last_response.status)

    get '/'

    refute_equal(session[:message], "#{random_file} does not exist")
  end

  def test_markdown
    create_document('about.md', '<h1>Ruby is...</h1>')

    get '/about.md'

    assert_equal(200, last_response.status)
    assert_equal('text/html;charset=utf-8', last_response['Content-Type'])
    assert_includes(last_response.body, '<h1>Ruby is...</h1>')
  end

  def test_edit_view_login
    create_document('history.txt', '1993 - Yukihiro')

    get '/history.txt/edit', {}, admin_session

    assert_equal(200, last_response.status)
    assert_equal('text/html;charset=utf-8', last_response['Content-Type'])
    assert_includes(last_response.body, '1993 - Yukihiro')
    assert_includes(last_response.body, '<textarea')
    assert_includes(last_response.body, '<button type="submit"')
  end

  def test_edit_view_logout
    create_document('history.txt', '1993 - Yukihiro')

    get '/history.txt/edit'

    assert_equal(302, last_response.status)
    assert_equal(session[:message], 'You must be signed in to do that.')
  end

  def test_edit_functionality_login
    create_document('changes.txt')

    # The param name comes from the id of the element
    post '/changes.txt/edit', { content: 'new content' }, admin_session

    # When testing, a redirection executed through Rack::Test will set a 302 regardless of request type
    # If you redirect in Sinatra from a POST route, the response will return a 303 status code
    # If you redirect in Sinatra from a GET route, then the response will return a 302
    assert_equal(302, last_response.status)
    assert_equal(session[:message], 'changes.txt has been updated.')

    get '/changes.txt'
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'new content')
  end

  def test_edit_functionality_logout
    create_document('changes.txt')

    post '/changes.txt/edit', content: 'new content'

    assert_equal(302, last_response.status)
    assert_equal(session[:message], 'You must be signed in to do that.')
  end

  def test_view_new_document_form_signin
    get '/new', {}, admin_session

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, '<input')
    assert_includes(last_response.body, "<button type='submit'")
  end

  def test_view_new_document_form_signout
    get '/new'

    assert_equal(302, last_response.status)
    assert_equal(session[:message], 'You must be signed in to do that.')
  end

  def test_create_new_document_signin
    post '/new', { new_doc: 'test.txt' }, admin_session
    assert_equal(302, last_response.status)
    assert_equal(session[:message], 'test.txt was created.')

    get '/'
    assert_includes(last_response.body, 'test.txt')
  end

  def test_create_new_document_signout
    post '/new', new_doc: 'test.txt'

    assert_equal(302, last_response.status)
    assert_equal(session[:message], 'You must be signed in to do that.')
  end

  def test_create_new_document_without_filename_login
    post '/new', { new_doc: '' }, admin_session

    assert_equal(422, last_response.status)
    # We can't use session[:message] here as we re-render the page instead of redirect
    # which clears the session variable
    assert_includes(last_response.body, 'A name is required')
  end

  def test_create_new_document_without_filename_logout
    post '/new', new_doc: ''

    assert_equal(302, last_response.status)
    assert_equal(session[:message], 'You must be signed in to do that.')
  end

  def test_delete_document_signin
    create_document('test.txt')
    post '/test.txt/delete', {}, admin_session

    assert_equal(302, last_response.status)
    assert_equal(session[:message], 'test.txt was deleted')

    get '/'
    assert_equal(200, last_response.status)
    refute_equal(session[:message], 'test.txt')
  end

  def test_delete_document_signout
    create_document('test.txt')
    post '/test.txt/delete'

    assert_equal(302, last_response.status)
    assert_equal(session[:message], 'You must be signed in to do that.')
  end

  def test_login_page
    get '/users/login'

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'Username')
    assert_includes(last_response.body, "<input name='password'")
  end

  def test_admin_login_success
    post '/users/login', username: ENV['USERNAME'], password: ENV['PASSWORD']

    assert_equal(302, last_response.status)
    assert_equal(session[:message], 'Welcome!')
    assert_equal(session[:login], 'success')

    # Use this when you need a logic based redirect
    get last_response['Location']

    assert_includes(last_response.body, 'Signed in as admin')
    assert_equal(session[:username], 'admin')
  end

  def test_login_failure
    post '/users/login', username: 'admIn', password: 'garbled_string'

    assert_equal(422, last_response.status)
    assert_nil(session[:username])
    assert_includes(last_response.body, 'Invalid Credentials')
  end

  def test_signout
    post '/users/logout'
    assert_equal('You have been signed out.', session[:message])

    get last_response['Location']

    assert_nil(session[:username])
    assert_includes(last_response.body, 'Sign In')
  end
end
