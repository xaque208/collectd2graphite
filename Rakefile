require 'rake'

task :default => 'gembuild'

desc "build the gem"
task :gembuild do
  %x(gem build ./collectd2graphite.gemspec)
end
