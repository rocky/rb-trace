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
TEST_FILES   = FileList['test/**/*.rb']
COMMON_FILES = FileList[%w(README Rakefile)]
ALL_FILES    = COMMON_FILES + TEST_FILES + EXT_FILES

desc 'Test units - the smaller tests'
task :'test:unit' => [:ext] do |t|
  Rake::TestTask.new(:'test:unit') do |t|
    t.test_files = FileList['test/unit/**/*.rb']
    # t.pattern = 'test/**/*test-*.rb' # instead of above
    t.verbose = true
  end
end

desc "Create the core ruby-debug shared library extension"
task :ext do
  Dir.chdir('ext') do
    system("#{Gem.ruby} extconf.rb && make")
  end
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
