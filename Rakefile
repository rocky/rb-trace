#!/usr/bin/env rake
# -*- Ruby -*-
require 'rubygems'
require 'fileutils'

ROOT_DIR = File.dirname(__FILE__)
Gemspec_filename='rb-trace.gemspec'

def gemspec
  @gemspec ||= eval(File.read(Gemspec_filename), binding, Gemspec_filename)
end

require 'rake/gempackagetask'
desc "Build the gem"
task :package=>:gem
task :gem=>:gemspec do
  Dir.chdir(ROOT_DIR) do
    sh "gem build #{Gemspec_filename}"
    FileUtils.mkdir_p 'pkg'
    FileUtils.mv gemspec.file_name, 'pkg'
  end
end

desc "Install the gem locally"
task :install => :gem do
  Dir.chdir(ROOT_DIR) do
    sh %{gem install --local pkg/#{gemspec.file_name}}
  end
end

require 'rake/testtask'
desc "Test everything."
task :test => [:lib, :'test:unit']

desc "Create a GNU-style ChangeLog via git2cl"
task :ChangeLog do
  system("git log --pretty --numstat --summary | git2cl > ChangeLog")
end

desc 'Test units - the smaller tests'
task :'test:unit' => :ext
Rake::TestTask.new(:'test:unit') do |t|
  t.libs << './ext'
  t.test_files = FileList['test/unit/**/*.rb']
  # t.pattern = 'test/**/*test-*.rb' # instead of above
  t.options = '--verbose' if $VERBOSE
end

desc "Create the core rb-trace shared library extension"
task :ext do
  Dir.chdir('ext') do
    system("#{Gem.ruby} extconf.rb && make")
  end if '1.9.2' == RUBY_VERSION
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

desc "Default action is same as 'test'."
task :default => :test

desc "Generate the gemspec"
task :generate do
  puts gemspec.to_ruby
end

desc "Validate the gemspec"
task :gemspec do
  gemspec.validate
end


