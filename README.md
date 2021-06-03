# Sinatra File-Based CMS App
A repo to contain a web-based CMS using Sinatra.

### Basic Overview
This is a basic CMS CRUD application written using the Sinatra framework, with login authentication for certain functionality.

Users are able to:
- Login/Logout
- View a list of documents stored in the `data/` directory
- View the documents in the `data/` directory, rendered as `.md` or `.txt` as appropriate
- Create documents (dependent on login status)
- Edit documents (dependent on login status)
- Delete documents (dependent on login status)

This makes use of layouts to reduce the amount of `erb` duplication across view templates. The `bcrypt` gem was used to encrypt stored passwords.

Note that this project uses the filesystem to persist data, and as a result, it isn't a good fit for Heroku. Applications running on Heroku only have access to an ephemeral filesystem. This means any files that are written by a program will be lost each time the application goes to sleep, is redeployed, or restarts (which typically happens every 24 hours).

### How to run
This project is only intended to run locally in development for the above mentioned reasons.
1. Clone the repo locally
2. Make sure you have the `bundle` gem installed.
2. Run `bundle install` in your CLI
3. Run `ruby cms.rb` in your CLI
4. Visit `http://localhost:4567` in your web browser
5. If you need to reset the app (i.e. delete all information), please delete the associated cookie through your browser.

Login credentials include:
```ruby
{
  # This is stored in a .env file
  admin: 'secret',
  # These are stored in users.yaml
  albert: 'blompy',
  timmy: 'wimmy',
  wimmish: 'plimmish'
}
```
### Tests
Tests are found in the `test/cms_test.rb` file. They can be executed through `bundle exec ruby cms_test.rb`.

### Design Choices
Referencing file locations is difficult when working locally, as we have no guarantee of where the user's current working directory is set when they execute the application code.

`File.expand_path` lets you determine the absolute path name that corresponds to a relative pathname. This is useful when we might be running the program from a different directory to where it's located (though I've used `File.expand_path(__dir__)` as this is what Rubocop seems to prefer).

Take the following code:
```ruby
File.expand_path("..", __FILE__)
```
`__FILE__` represents the name of the file that contains the reference to `__FILE__`. E.g. if your file is named `myprog.rb` and you run it with `ruby myprog.rb`, then `__FILE__` is `myprog.rb`. 

If we combine this value with `'..'` in the call to `expand_path`, we get the absolute path name of the directory where our program lives. For instance, if `myprog.rb` is in the `/Users/me/project` directory, then the method call returns `/Users/me/project`. This value lets us access other files in our project directory __without__ having to use _relative_ path names.

### Challenges
