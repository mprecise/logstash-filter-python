Gem::Specification.new do |s|
  s.name = 'logstash-filter-python'
  s.version         = '0.0.1'
  s.licenses = ['Apache License (2.0)']
  s.summary = "Filter for executing python code on the event."
  s.description = "This gem is a logstash plugin required to be installed on top of the Logstash core pipeline using $LS_HOME/bin/plugin install gemname. This gem is not a stand-alone program"
  s.authors = ["Michael Precise"]
  s.email = 'mprecise@users.noreply.github.com'
  s.homepage = "https://github.com/mprecise/logstash-filter-python"
  s.require_paths = ["lib"]
  s.files = Dir['lib/**/*','spec/**/*','vendor/**/*','*.gemspec','*.md','CONTRIBUTORS','Gemfile','LICENSE','NOTICE.TXT']
  s.test_files = s.files.grep(%r{^(test|spec|features)/})
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "filter" }
  s.add_runtime_dependency "logstash-core", ">= 2.0.0", "< 3.0.0"
  s.add_runtime_dependency "rubypython", "~> 0.6.3"
  s.add_development_dependency "logstash-devutils", "~> 0.0.18"
end

