require 'pry'
require 'carrierwave'
require 'carrierwave/ffmpeg'

RSpec.configure do |config|
  config.raise_errors_for_deprecations!
  config.mock_with :rspec
end
