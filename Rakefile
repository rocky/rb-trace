#!/usr/bin/env rake
# -*- Ruby -*-
require 'rubygems'
require 'fileutils'

ROOT_DIR = File.dirname(__FILE__)
Gemspec_filename='rb-trace.gemspec'

def gemspec
  @gemspec ||= eval(File.read(Gemspec_filename), binding, Gemspec_filename)
end

require 'rubygems/package_task'
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
task :'test:unit'
Rake::TestTask.new(:'test:unit') do |t|
  t.test_files = FileList['test/unit/**/*.rb']
  # t.pattern = 'test/**/*test-*.rb' # instead of above
  t.options = '--verbose' if $VERBOSE
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


