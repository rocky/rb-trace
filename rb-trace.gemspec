# -*- Ruby -*-
# -*- encoding: utf-8 -*-
require 'rake'

PACKAGE_VERSION = open('ext/trace.c') do |f| 
  f.grep(/^#define TRACE_VERSION/).first[/"(.+)"/,1]
end

spec = Gem::Specification.new do |spec|
  spec.name = "rb-trace"
  
  spec.homepage = "http://github.com/rocky/rb-trace/tree/master"
  spec.summary = "Trace hook extensions"
  spec.description = <<-EOF

rb-trace adds a trace_hook object, translates hooks bitmasks to sets
and vice versa, and extends set_trace_func to ignore frames or
functions.
EOF

  spec.version = PACKAGE_VERSION
  spec.extensions = ['ext/extconf.rb']

  spec.author = "R. Bernstein"
  spec.email = "rockyb@rubyforge.org"
  spec.platform = Gem::Platform::RUBY
  spec.files = `git ls-files`.split("\n")
  spec.add_dependency('rb-threadframe', '~> 0.40')

  spec.required_ruby_version = '~> 1.9.2frame'
  spec.date = Time.now
  # spec.rubyforge_project = 'rocky-hacks'
  
  # rdoc
  spec.has_rdoc = true
  # spec.extra_rdoc_files = ['README', 'threadframe.rd']
end

