require 'bundler/setup'
require File.expand_path '../api', __FILE__

use Rack::Stream
run API
