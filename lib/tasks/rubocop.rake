# frozen_string_literal: true

namespace :rubocop do
  desc 'Run RuboCop with auto-correct and check if any offenses remain'
  task check_and_correct: :environment do
    puts 'Running RuboCop with auto-correction...'
    system('bundle exec rubocop -a --disable-uncorrectable')

    puts "\nChecking for remaining offenses..."
    result = system('bundle exec rubocop --display-only-fail-level-offenses')

    if result
      puts '✅ No RuboCop offenses found!'
    else
      puts '❌ RuboCop offenses still exist. Please fix them manually.'
      exit 1
    end
  end

  desc 'Run RuboCop only on changed files'
  task :changed do
    changed_files = `git diff --name-only --diff-filter=ACM HEAD~1 HEAD`.split("\n")
    ruby_files = changed_files.select { |f| f.end_with?('.rb') }

    if ruby_files.empty?
      puts 'No Ruby files changed.'
    else
      puts "Running RuboCop on changed Ruby files: #{ruby_files.join(', ')}"
      system("bundle exec rubocop #{ruby_files.join(' ')}")
    end
  end

  desc 'Run RuboCop on files that will be committed'
  task :staged do
    staged_files = `git diff --cached --name-only --diff-filter=ACM`.split("\n")
    ruby_files = staged_files.select { |f| f.end_with?('.rb') }

    if ruby_files.empty?
      puts 'No Ruby files staged for commit.'
    else
      puts "Running RuboCop on staged Ruby files: #{ruby_files.join(', ')}"
      system("bundle exec rubocop #{ruby_files.join(' ')}")
    end
  end

  desc 'Run RuboCop on Rails generated files'
  task :generated do
    generated_patterns = [
      'app/models/*.rb',
      'app/controllers/*.rb',
      'app/views/**/*.*.slim',
      'db/migrate/*.rb',
      'test/**/*_test.rb'
    ]

    generated_patterns.each do |pattern|
      files = Dir.glob(pattern)
      next if files.empty?

      puts "Checking #{pattern} files..."
      system("bundle exec rubocop #{files.join(' ')}")
    end
  end

  desc 'Setup RuboCop Git pre-commit hook'
  task :setup_hook do
    hook_path = File.join(Rails.root, '.git', 'hooks', 'pre-commit')
    script_path = File.join(Rails.root, 'bin', 'rubocop-hook')

    if File.exist?(hook_path)
      puts 'Pre-commit hook already exists. Skipping.'
    else
      File.symlink(script_path, hook_path)
      puts 'Pre-commit hook installed successfully!'
    end
  end
end

# Override default Rails generators task to run RuboCop after generation
Rake::Task['app:templates:copy'].enhance do
  Rake::Task['rubocop:generated'].invoke if defined?(Rails)
end