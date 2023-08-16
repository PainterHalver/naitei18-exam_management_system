# This file is used by Rack-based servers to start the application.

require_relative "config/environment"
require "rack/cors"
require "rack/attack"

use Rack::Cors do
  allow do
    origins "*"
    resource "*", headers: :any,
             methods: %i(get post put patch delete options head)
  end
end
use Rack::Attack

run Rails.application
Rails.application.load_server
