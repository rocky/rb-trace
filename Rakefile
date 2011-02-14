#!/usr/bin/env rake
# -*- Ruby -*-
require 'rubygems'
require 'rake/gempackagetask'
require 'rake/testtask'

SO_NAME = 'trace.so'

PACKAGE_VERSION = open('ext/trace.c') do |f| 
  f.grep(/^#define TRACE_VERSION/).first[/"(.+)"/,1]
end

EXT_FILES    = FileList[%w(ext/*.c ext/*.h)]
LIB_FILES    = FileList['lib/*.rb']
TEST_FILES   = FileList['test/**/*.rb']
COMMON_FILES = FileList[%w(Rakefile NEWS LICENSE README.textile)]
ALL_FILES    = COMMON_FILES + TEST_FILES + EXT_FILES + LIB_FILES

desc "Create a GNU-style ChangeLog via git2cl"
task :ChangeLog do
  system("git log --pretty --numstat --summary | git2cl > ChangeLog")
end

desc 'Test units - the smaller tests'
task :'test:unit' => [:ext] do |t|
  Rake::TestTask.new(:'test:unit') do |t|
    t.test_files = FileList['test/unit/**/*.rb']
    # t.pattern = 'test/**/*test-*.rb' # instead of above
    t.options = '--verbose' if $VERBOSE
  end
end

desc "Create the core ruby-debug shared library extension"
task :ext do
  Dir.chdir('ext') do
    system("#{Gem.ruby} extconf.rb && make")
  end
end

desc 'Create a GNU-style ChangeLog via git2cl'
task :ChangeLog do
  system('git log --pretty --numstat --summary | git2cl > ChangeLog')
end

desc 'Remove built files'
task :clean do
  cd 'ext' do
    if File.exist?('Makefile')
      sh 'make clean'
      rm  'Makefile'
    end
    derived_files = Dir.glob('.o') + Dir.glob('*.so')
    rm derived_files unless derived_files.empty?
  end
end

desc 'Test everything - unit tests for now.'
task :test do
  exceptions = ['test:unit'].collect do |task|
    begin
      Rake::Task[task].invoke
      nil
    rescue => e
      e
    end
  end.compact
end

desc "Test everything - same as test."
task :check => :test
task :default => [:test]

# Base GEM Specification
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
  spec.files = ALL_FILES.to_a  
  spec.add_dependency('rb-threadframe', '~> 0.38.dev')

  spec.required_ruby_version = '~> 1.9.2frame'
  spec.date = Time.now
  # spec.rubyforge_project = 'rocky-hacks'
  
  # rdoc
  spec.has_rdoc = true
  # spec.extra_rdoc_files = ['README', 'threadframe.rd']
end

# Rake task to build the default package
Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = true
end

def install(spec, *opts)
  args = ['gem', 'install', "pkg/#{spec.name}-#{spec.version}.gem"] + opts
  system(*args)
end

desc 'Install locally'
task :install => :package do
  Dir.chdir(File::dirname(__FILE__)) do
    # ri and rdoc take lots of time
    install(spec, '--no-ri', '--no-rdoc')
  end
end    

task :install_full => :package do
  Dir.chdir(File::dirname(__FILE__)) do
    install(spec)
  end
end
