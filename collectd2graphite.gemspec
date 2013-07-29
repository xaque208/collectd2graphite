Gem::Specification.new do |gem|

  gem.name    = 'collectd2graphite'
  gem.version = '0.0.1'
  gem.date    = Date.today.to_s

  gem.summary     = "Convert json blob from collectd to graphite"
  gem.description = "Convert json blob received from collectd's write_http plugin into graphite formatted data'"

  gem.author   = 'Zach Leslie'
  gem.email    = 'xaque208@gmail.com'
  gem.homepage = 'https://github.com/xaque208/collectd2graphite'

  # ensure the gem is built out of versioned files
   gem.files = Dir['Rakefile', '{bin,lib}/**/*', 'README*', 'LICENSE*'] & %x(git ls-files -z).split("\0")

   gem.add_dependency('json')
   gem.add_dependency('json2graphite')

end


