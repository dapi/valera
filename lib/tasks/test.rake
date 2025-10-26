# Custom test task to run Minitest
desc "Run all tests (Minitest)"
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

  puts "\n✅ All tests passed successfully!"
end

# Make this the default task
unless Rails.env.production?
  # Clear any existing default task and set ours
  Rake::Task[:default].clear if Rake::Task.task_defined?(:default)
  task default: :all_tests
end
