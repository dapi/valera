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

    desc "Check documentation quality"
    task :quality do
      puts "🔍 Checking documentation quality..."

      # Check for missing @param and @return tags
      missing_docs = `bundle exec yard stats --list-undoc 2>/dev/null`

      if missing_docs.empty?
        puts "✅ All documented methods found"
      else
        puts "⚠️  Missing documentation found:"
        puts missing_docs
      end

      # Check for TODO/FIXME tags in documentation
      todo_count = `grep -r '@todo' app/ lib/ 2>/dev/null | wc -l`.to_i
      fixme_count = `grep -r '@fixme' app/ lib/ 2>/dev/null | wc -l`.to_i

      puts "📝 Documentation statistics:"
      puts "  - TODO items: #{todo_count}"
      puts "  - FIXME items: #{fixme_count}"

      if todo_count > 0 || fixme_count > 0
        puts "📋 Documentation items to address:"
        system("grep -r '@todo\\|@fixme' app/ lib/ 2>/dev/null || true")
      end
    end
  end

  # Add shorthand aliases
  task yard: 'doc:generate'
  task yard_server: 'doc:serve'
  task yard_clean: 'doc:clean'

rescue LoadError
  puts "⚠️  YARD gem not found. Add it to your Gemfile and run bundle install"
end
