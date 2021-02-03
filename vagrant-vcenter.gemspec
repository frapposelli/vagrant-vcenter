# encoding: UTF-8
$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'vagrant-vcenter/version'

Gem::Specification.new do |s|
  s.name = 'vagrant-vcenter'
  s.version = VagrantPlugins::VCenter::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = 'Fabio Rapposelli'
  s.email = 'fabio@rapposelli.org'
  s.homepage = 'https://github.com/frapposelli/vagrant-vcenter'
  s.license = 'MIT'
  s.summary = 'VMware vCenter® Vagrant provider'
  s.description = 'Enables Vagrant to manage machines with VMware vCenter®.'

  s.add_runtime_dependency 'vagrant-rbvmomi', '~> 1.8.1'
  s.add_runtime_dependency 'log4r', '~> 1.1.10'

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec-core', '~> 2.12.2'
  s.add_development_dependency 'rspec-expectations', '~> 2.12.1'
  s.add_development_dependency 'rspec-mocks', '~> 2.12.1'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'code-scanning-rubocop', '~> 0.5'

  s.files = `git ls-files`.split($RS)
  s.executables = s.files.grep(/^bin/) { |f| File.basename(f) }
  s.test_files = s.files.grep(/^(test|spec|features)/)
  s.require_path = 'lib'
end
