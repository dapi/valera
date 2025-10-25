# Custom test task to run both Minitest and RSpec
desc "Run all tests (Minitest + RSpec)"
task :all_tests do
  puts "Running all tests..."

  # Run Minitest tests
  puts "\n=== Running Minitest tests ==="
  minitest_success = system("bundle exec rails test")

  if minitest_success
    puts "Minitest tests passed!"
  else
    puts "Minitest tests failed!"
    exit 1
  end

  # Run RSpec tests
  puts "\n=== Running RSpec tests ==="
  rspec_success = system("bundle exec rspec")

  if rspec_success
    puts "RSpec tests passed!"
  else
    puts "RSpec tests failed!"
    exit 1
  end

  puts "\n✅ All tests passed successfully!"
end

# Make this the default task instead of RSpec's spec task
unless Rails.env.production?
  # Clear any existing default task and set ours
  Rake::Task[:default].clear if Rake::Task.task_defined?(:default)
  task :default => :all_tests
end