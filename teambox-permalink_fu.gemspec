# -*- encoding: utf-8 -*-
$LOAD_PATH.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'teambox-permalink_fu'
  s.version     = '1.0.4'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Gonçalo Silva", 'Charles Barbier']
  s.email       = ['goncalossilva@gmail.com', 'unixcharles@gmail.com']
  s.homepage    = 'http://rubygems.org/gems/teambox-permalink_fu'
  s.summary     = 'Fork of permalink_fu used at Teambox'
  s.description = 'Same functionality as the original one, except now it ' \
                  "doesn't accept numerical permalinks and is safer with" \
                  'unicode characters.'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test}/*`.split("\n")
  s.require_paths = ['lib']
end
