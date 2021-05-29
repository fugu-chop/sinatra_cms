# Sinatra File-Based CMS App
A repo to contain a web-based CMS using Sinatra.

### Basic Overview

### How to run
This project uses the filesystem to persist data, and as a result, it isn't a good fit for Heroku. Applications running on Heroku only have access to an ephemeral filesystem. This means any files that are written by a program will be lost each time the application goes to sleep, is redeployed, or restarts (which typically happens every 24 hours).

### Tests
Tests are found in the `test/cms_test.rb` file. They can be executed through `bundle exec ruby cms_test.rb`.

### Design Choices

### Challenges
