# frozen_string_literal: true

# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative 'config/application'

Rails.application.load_tasks

# YARD Documentation tasks
begin
  require 'yard'
  require 'yard/rake/yardoc_task'

  namespace :doc do
    desc "Generate YARD documentation"
    YARD::Rake::YardocTask.new(:generate) do |t|
      t.files = [ 'app/**/*.rb', 'lib/**/*.rb', '-', 'README.md' ]
      t.options = [ '--output-dir', 'doc/yard', '--markup', 'markdown', '--title', 'Valera API Documentation' ]
    end

    desc "Regenerate documentation with cache reset"
    task regenerate: [ 'doc:clean', 'doc:generate' ]

    desc "Clean generated documentation"
    task :clean do
      rm_rf 'doc/yard'
      rm_rf '.yardoc'
    end

    desc "Start YARD server for local documentation viewing"
    task :serve do
      sh "bundle exec yard server --reload --port 8808"
    end

    desc "Validate YARD documentation coverage"
    task :coverage do
      sh "bundle exec yard stats --list-undoc"
    end

    desc "Generate complete documentation with coverage report"
    task complete: [ :generate, :coverage ]
  end

  # Add shorthand aliases
  task yard: 'doc:generate'
  task yard_server: 'doc:serve'
  task yard_clean: 'doc:clean'

rescue LoadError
  puts "⚠️  YARD gem not found. Add it to your Gemfile and run bundle install"
end
