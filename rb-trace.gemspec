# -*- Ruby -*-
# -*- encoding: utf-8 -*-
require 'rake'
require 'rubygems' unless 
  Object.const_defined?(:Gem)

require File.dirname(__FILE__) + '/lib/trace' unless 
  Object.const_defined?(:'Trace') and Trace.const_defined?(:VERSION)

spec = Gem::Specification.new do |spec|
  spec.authors      = ['R. Bernstein']
  spec.name         = 'rb-trace'
  
  spec.homepage     = 'https://github.com/rocky/rb-trace/wiki'
  spec.summary      = 'Trace hook extensions'
  spec.description  = <<-EOF

rb-trace adds a trace_hook object, translates hooks bitmasks to Ruby sets and vice versa, and extends set_trace_func() to allow ignore specified frames or functions.
EOF

  spec.version      = Trace::VERSION

  spec.email        = 'rockyb@rubyforge.org'
  spec.platform     = Gem::Platform::RUBY
  spec.files        = `git ls-files`.split("\n")
  spec.add_dependency('rb-threadframe', '>= 0.41')

  # spec.required_ruby_version = '~> 1.9.2frame'
  spec.date = Time.now
  # spec.rubyforge_project = 'rocky-hacks'
  
  # rdoc
  spec.has_rdoc = true
  # spec.extra_rdoc_files = ['README', 'threadframe.rd']
end

