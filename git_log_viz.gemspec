Gem::Specification.new do |s|
  s.name        = 'git_log_viz'
  s.version     = '1.0.0'
  s.date        = '2015-06-17'
  s.summary     = 'Visualize git repository history with GraphViz'
  s.author      = 'Benjamin Ragheb'
  s.email       = 'ben@benzado.com'
  s.homepage    = 'https://github.com/benzado/gitlogviz'
  s.license     = 'GPL-3.0'

  s.files       = Dir[
    'bin/*',
    'lib/**/*.rb',
    'test/**/*.rb',
  ]
  s.executables << 'gitlogviz'
end
