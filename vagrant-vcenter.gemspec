$:.unshift File.expand_path('../lib', __FILE__)
require 'vagrant-vcenter/version'

Gem::Specification.new do |s|
  s.name = 'vagrant-vcenter'
  s.version = VagrantPlugins::VCenter::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = 'Fabio Rapposelli'
  s.email = 'fabio@gosddc.com'
  s.homepage = 'https://github.com/gosddc/vagrant-vcenter'
  s.license = 'MIT'
  s.summary = 'VMware vCenter® Vagrant provider'
  s.description = 'Enables Vagrant to manage machines with VMware vCenter®.'
  
  s.add_runtime_dependency 'rbvmomi', '~> 1.6.0'
  s.add_runtime_dependency 'log4r', '~> 1.1.10'
  
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec-core", "~> 2.12.2"
  s.add_development_dependency "rspec-expectations", "~> 2.12.1"
  s.add_development_dependency "rspec-mocks", "~> 2.12.1"
  
  s.files = `git ls-files`.split($/)
  s.executables = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files = s.files.grep(%r{^(test|spec|features)/})
  s.require_path = 'lib'
end
