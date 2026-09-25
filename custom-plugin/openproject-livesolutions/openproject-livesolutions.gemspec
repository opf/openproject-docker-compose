Gem::Specification.new do |s|
  s.name        = 'openproject-livesolutions'
  s.version     = '1.0.0'
  s.authors     = ['Live Solutions']
  s.email       = ['anthony@livesolutionsnow.com']
  s.summary     = 'Live Solutions brand plugin for OpenProject'
  s.description = 'Injects custom CSS, favicon and logo for Live Solutions brand identity on OpenProject Community Edition.'
  s.license     = 'GPL-3.0-or-later'

  s.files = Dir['lib/**/*', 'app/**/*', 'config/**/*', 'README.md']
  s.require_paths = ['lib']
end
