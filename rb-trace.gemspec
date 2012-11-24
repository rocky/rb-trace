# -*- Ruby -*-
# -*- encoding: utf-8 -*-
require 'rake'

PACKAGE_VERSION = open('ext/1.9.2/trace.c') do |f| 
  f.grep(/^#define TRACE_VERSION/).first[/"(.+)"/,1]
end

if '1.9.2' == RUBY_VERSION
  EXT_FILES     = FileList[%W(ext/#{RUBY_VERSION}/*.c 
                              ext/#{RUBY_VERSION}/*.h)] 
  INCLUDE_FILES = FileList['include/*.h']
else
  EXT_FILES     = []
  INCLUDE_FILES = FileList[]
end
LIB_FILES     = FileList['lib/*.rb']
TEST_FILES    = FileList['test/**/*.rb']
COMMON_FILES  = FileList[%w(README.textile Rakefile LICENSE NEWS)]
FILES         = COMMON_FILES + INCLUDE_FILES + LIB_FILES + EXT_FILES + 
  TEST_FILES

spec = Gem::Specification.new do |spec|
  spec.authors      = ['R. Bernstein']
  spec.name = "rb-trace"
  
  spec.homepage = "http://github.com/rocky/rb-trace/tree/master"
  spec.summary = "Trace hook extensions"
  spec.description = <<-EOF

rb-trace adds a trace_hook object, translates hooks bitmasks to sets
and vice versa, and extends set_trace_func to ignore frames or
functions.
EOF

  spec.version      = PACKAGE_VERSION
  spec.extensions   = ["ext/extconf.rb"] if '1.9.2' == RUBY_VERSION

  spec.email        = "rockyb@rubyforge.org"
  spec.platform     = Gem::Platform::RUBY
  spec.files        = FILES.to_a  
  spec.add_dependency('rb-threadframe', '>= 0.39.9')

  # spec.required_ruby_version = '~> 1.9.2frame'
  spec.date = Time.now
  # spec.rubyforge_project = 'rocky-hacks'
  
  # rdoc
  spec.has_rdoc = true
  # spec.extra_rdoc_files = ['README', 'threadframe.rd']
end

