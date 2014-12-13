require "capistrano/postgresql/version"
require "capistrano/ubuntu"

module Capistrano
  module Postgresql
    # Your code goes here...
  end
end


import File.expand_path("../tasks/postgresql.rake", __FILE__)
