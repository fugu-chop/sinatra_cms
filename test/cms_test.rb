ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"
require_relative "../cms"

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_index
    get "/"

    assert_equal(200, last_response.status)
    assert_equal("text/html;charset=utf-8", last_response["Content-Type"])
    assert_includes(last_response.body, "about.md")
    assert_includes(last_response.body, "changes.txt")
    assert_includes(last_response.body, "history.txt")
  end

  def test_viewing_text_document
    get "/history.txt"

    assert_equal(200, last_response.status)
    assert_equal("text/plain", last_response["Content-Type"])
    assert_includes(last_response.body, "Ruby 0.95 released")
  end

  def test_invalid_file
    def generate_code(number)
      charset = ('a'..'z').to_a
      Array.new(number) { charset.sample }.join
    end
    random_file = "#{generate_code(10)}.txt"

    get "/#{random_file}"

    assert_equal(302, last_response.status)
    # Request the page that the user was redirected to
    get last_response["Location"]
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "#{random_file} does not exist")

    get "/"
    refute_includes(last_response.body, "#{random_file} does not exist")
  end

  def test_markdown
    get "/about.md"

    assert_equal(200, last_response.status)
    assert_equal("text/html;charset=utf-8", last_response["Content-Type"])
    assert_includes(last_response.body, "<h1>Ruby is...</h1>")
  end

  def test_edit_view
    get "/history.txt/edit"

    assert_equal(200, last_response.status)
    assert_equal("text/html;charset=utf-8", last_response["Content-Type"])
    assert_includes(last_response.body, "1993 - Yukihiro")
    assert_includes(last_response.body, "<textarea")
    assert_includes(last_response.body, %q(<button type="submit"))
  end

  def test_edit_functionality
    post "/changes.txt/edit", content: "new content"

    # When testing, a redirection executed through Rack::Test will set a 302 regardless of request type
    # If you redirect in Sinatra from a POST route, the response will return a 303 status code
    # If you redirect in Sinatra from a GET route, then the response will return a 302
    assert_equal(302, last_response.status)

    get last_response["Location"]
    assert_includes(last_response.body, "changes.txt has been updated")

    get "/changes.txt"
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "new content")
  end
end
