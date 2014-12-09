require 'epp-client/base'
require 'util/test_util.rb'


RSpec.configure do |config|
  config.mock_with :rspec
  config.filter_run wip: true
  config.run_all_when_everything_filtered = true
  config.fail_fast = false
end