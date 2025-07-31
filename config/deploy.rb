# config valid for current version and patch releases of Capistrano
lock "~> 3.19.2"

set :application, "gingga"
set :repo_url, "git@github.com:vlaguzman/gingga.git"
set :deploy_to, "/var/www/#{fetch(:application)}"

set :rvm_type, :user
set :rvm_ruby_version, 'ruby-3.4.2' # or your actual version

set :linked_files, %w[config/database.yml config/master.key]
set :linked_dirs, %w[log tmp/pids tmp/cache tmp/sockets public/system storage]

set :keep_releases, 5
