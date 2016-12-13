$LOAD_PATH.unshift 'lib'
require 'monkey-reloader/version'


Gem::Specification.new do |s|
  s.name        = 'monkey-reloader'
  s.version     = MonkeyReloader::VERSION
  s.summary     = "Monkey Reloading"
  s.authors     = ["Daniel Pepper"]
  s.files       = Dir.glob("lib/**/*")
  s.homepage    = 'http://rubygems.org/gems/monkey_reloader'
  s.license     = 'MIT'
  s.description = <<description
    fast IRB reloading for non-conventional file naming, using git
    change tracking
description
end
