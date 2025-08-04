# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

# Run the project locally
```bash
git clone git@github.com:vlaguzman/gingga.git
cd gingga/
docker-compose up -d        # To run postgres  and selenium.
bundle                      # To install Gems
yarn                        # To install node packages
bundle exec rails db:setup  # To create the databases
bin/dev                     # To run rails server on port 3000
```

# Before pushing changes to Github
```
bash bin/shot        # To run linters and verifications,
# this includes running the tests. If you want to
# run the tests separately, run:
bundle exec rspec spec
```
