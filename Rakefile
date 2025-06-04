# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"

RuboCop::RakeTask.new

require "rake/extensiontask"

desc "Build the gem including native extensions"
task build: :compile

GEMSPEC = Gem::Specification.load("xmp_toolkit_ruby.gemspec")

Rake::ExtensionTask.new("xmp_toolkit_ruby", GEMSPEC) do |ext|
  ext.lib_dir = "lib/xmp_toolkit_ruby"
end

task default: %i[clobber compile spec rubocop]
