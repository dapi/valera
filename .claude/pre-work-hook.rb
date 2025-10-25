#!/usr/bin/env ruby

# Pre-Work Hook for Claude
# This script should be executed before any telegram-related work

require 'fileutils'
require 'json'

class PreWorkHook
  LEARNING_STATE_FILE = File.expand_path('~/.claude/learning_state.json')
  CHECKLIST_FILE = File.expand_path('../telegram-checklist.md', __dir__)

  def initialize
    @learning_state = load_learning_state
  end

  def run(query = nil, files = [])
    puts "\n" + "="*60
    puts "🤖 CLAUDE PRE-WORK HOOK - TELEGRAM BOT"
    puts "="*60

    # Check if this is ruby_llm-related work first (more specific)
    if ruby_llm_related?(query, files)
      execute_ruby_llm_learning_protocol(query)
    elsif telegram_related?(query, files)
      execute_telegram_learning_protocol(query)
    else
      puts "ℹ️  No telegram or ruby_llm related content detected. Proceeding normally."
    end

    puts "="*60 + "\n"
  end

  private

  def telegram_related?(query, files)
    return true if query && telegram_keywords_in_query?(query)
    return true if files && files.any? { |file| telegram_keywords_in_file?(file) }
    false
  end

  def telegram_keywords_in_query?(query)
    keywords = %w[
      telegram bot webhook chat message inline
      callback keyboard button tg_ telegr bot_token
      command handler reply markup
    ]

    query.downcase.match?(/#{keywords.join('|')}/)
  end

  def telegram_keywords_in_file?(file)
    file_patterns = [
      /telegram|bot|webhook|chat/i,
      /app\/models\/chat/,
      /app\/models\/message/,
      /config\/initializers\/.*telegram/
    ]

    file_patterns.any? { |pattern| file.match?(pattern) }
  end

  def execute_telegram_learning_protocol(query)
    puts "\n🚨 **TELEGRAM-RELATED WORK DETECTED**"
    puts "📝 Query: #{query}" if query
    puts "\n⏰ **INITIATING MANDATORY LEARNING PROTOCOL**"

    # Check last study time
    last_study = @learning_state['telegram_bot_last_study']
    current_time = Time.now

    if should_refresh_learning?(last_study, current_time)
      perform_telegram_learning_sequence(query)
      update_learning_state('telegram_bot_last_study', current_time)
    else
      puts "\n✅ Recent study detected (#{time_since_study(last_study)})"
      puts "🔄 Performing quick refresher..."
      perform_telegram_quick_refresher
    end

    display_telegram_checklist
  end

  def execute_ruby_llm_learning_protocol(query)
    puts "\n🚨 **RUBY LLM-RELATED WORK DETECTED**"
    puts "📝 Query: #{query}" if query
    puts "\n⏰ **INITIATING MANDATORY LEARNING PROTOCOL**"

    # Check last study time
    last_study = @learning_state['ruby_llm_last_study']
    current_time = Time.now

    if should_refresh_learning?(last_study, current_time)
      perform_ruby_llm_learning_sequence(query)
      update_learning_state('ruby_llm_last_study', current_time)
    else
      puts "\n✅ Recent study detected (#{time_since_study(last_study)})"
      puts "🔄 Performing quick refresher..."
      perform_ruby_llm_quick_refresher
    end

    display_ruby_llm_checklist
  end

  def should_refresh_learning?(last_study, current_time)
    return true if last_study.nil?

    last_study_time = last_study.is_a?(Time) ? last_study : Time.parse(last_study)
    hours_since_study = (current_time - last_study_time) / 3600

    hours_since_study > 24  # Refresh if more than 24 hours
  end

  def time_since_study(last_study)
    return "Never studied" if last_study.nil?

    last_study_time = last_study.is_a?(Time) ? last_study : Time.parse(last_study)
    hours_ago = ((Time.now - last_study_time) / 3600).round

    if hours_ago < 1
      "Less than 1 hour ago"
    elsif hours_ago < 24
      "#{hours_ago} hours ago"
    else
      days = (hours_ago / 24).round
      "#{days} days ago"
    end
  end

  def perform_full_learning_sequence(query)
    puts "\n📚 **FULL LEARNING SEQUENCE**"

    sections = [
      {
        title: "Core Documentation",
        file: "docs/gems/telegram-bot/README.md",
        duration: "5 minutes",
        focus: "Basic setup, API structure, core concepts"
      },
      {
        title: "API Reference",
        file: "docs/gems/telegram-bot/api-reference.md",
        duration: "10 minutes",
        focus: "Complete API methods, parameters, error handling"
      },
      {
        title: "Architecture Patterns",
        file: "docs/gems/telegram-bot/patterns.md",
        duration: "10 minutes",
        focus: "Design patterns, best practices, scalability"
      }
    ]

    sections.each do |section|
      study_section(section)
    end

    study_examples
    analyze_current_implementation
    validate_knowledge
  end

  def perform_quick_refresher
    puts "\n⚡ **QUICK REFRESHER**"

    # Quick review of key concepts
    key_points = [
      "✅ Telegram bot uses token-based authentication",
      "✅ Support both long polling and webhook modes",
      "✅ Command patterns for handling user input",
      "✅ Inline and reply keyboards for user interaction",
      "✅ File handling for photos, documents, etc.",
      "✅ Error handling and rate limiting essential",
      "✅ Rails integration via controllers or jobs"
    ]

    key_points.each { |point| puts "   #{point}" }

    puts "\n🔍 **Quick implementation check:**"
    check_implementation_status
  end

  def study_section(section)
    puts "\n📖 **Studying: #{section[:title]}** (~#{section[:duration]})"
    puts "📁 File: #{section[:file]}"
    puts "🎯 Focus: #{section[:focus]}"

    if File.exist?(section[:file])
      content = File.read(section[:file])
      lines_count = content.lines.count
      puts "📄 Document length: #{lines_count} lines"

      # Extract key insights
      insights = extract_section_insights(section[:file], content)
      if insights.any?
        puts "💡 Key insights:"
        insights.each { |insight| puts "   • #{insight}" }
      end
    else
      puts "⚠️  File not found: #{section[:file]}"
    end
  end

  def study_examples
    puts "\n💻 **STUDYING CODE EXAMPLES**"

    examples = [
      {
        file: "docs/gems/telegram-bot/examples/advanced-handlers.rb",
        description: "Advanced message handling with state"
      }
    ]

    examples.each do |example|
      study_example(example)
    end
  end

  def study_example(example)
    puts "\n🔧 Example: #{example[:description]}"
    puts "📁 File: #{example[:file]}"

    if File.exist?(example[:file])
      content = File.read(example[:file])

      # Extract key patterns
      patterns = extract_example_patterns(content)
      if patterns.any?
        puts "🏗️  Key patterns:"
        patterns.each { |pattern| puts "   • #{pattern}" }
      end
    else
      puts "⚠️  Example file not found"
    end
  end

  def analyze_current_implementation
    puts "\n🔍 **ANALYZING CURRENT IMPLEMENTATION**"

    # Check for existing telegram code
    checks = [
      {
        name: "Models",
        pattern: "app/models/*",
        keywords: ["chat", "message", "telegram", "bot"]
      },
      {
        name: "Controllers",
        pattern: "app/controllers/*",
        keywords: ["telegram", "webhook", "bot"]
      },
      {
        name: "Configuration",
        pattern: "config/**/*",
        keywords: ["telegram", "bot"]
      }
    ]

    checks.each do |check|
      analyze_component(check)
    end
  end

  def analyze_component(check)
    puts "\n📊 #{check[:name]}:"

    found_files = []

    Dir.glob(check[:pattern]).each do |file|
      next unless File.file?(file)

      content = File.read(file)
      if check[:keywords].any? { |keyword| content.downcase.include?(keyword) }
        found_files << file
      end
    end

    if found_files.any?
      puts "   Found #{found_files.length} relevant file(s):"
      found_files.each { |file| puts "   • #{file}" }
    else
      puts "   No relevant files found"
    end
  end

  def validate_knowledge
    puts "\n🧠 **KNOWLEDGE VALIDATION**"

    questions = [
      "What telegram functionality currently exists?",
      "How is authentication configured?",
      "What message types are supported?",
      "Which API methods are needed for common tasks?",
      "How are errors handled in the current implementation?"
    ]

    puts "\n📋 Self-assessment questions (Claude should be able to answer these):"
    questions.each_with_index do |question, index|
      puts "   #{index + 1}. #{question}"
    end

    puts "\n✅ Claude must validate understanding before proceeding"
  end

  def display_checklist
    puts "\n📋 **PRE-WORK CHECKLIST**"
    puts "Please ensure Claude completes this checklist:"
    puts "📄 Full checklist available: #{CHECKLIST_FILE}"

    checklist_items = [
      "□ Documentation study completed",
      "□ Current implementation analyzed",
      "□ Knowledge validation passed",
      "□ Task-specific preparation complete",
      "□ Ready to proceed: Yes/No"
    ]

    checklist_items.each { |item| puts "   #{item}" }
  end

  def check_implementation_status
    # Quick checks for common implementation indicators
    checks = [
      { file: "Gemfile", pattern: /telegram-bot/ },
      { file: "config/routes.rb", pattern: /webhook|telegram/ },
      { file: "app/models/application_record.rb", pattern: /acts_as/ }
    ]

    checks.each do |check|
      if File.exist?(check[:file])
        content = File.read(check[:file])
        if content.match?(check[:pattern])
          puts "   ✅ Found telegram references in #{check[:file]}"
        end
      end
    end
  end

  def extract_section_insights(file_path, content)
    case File.basename(file_path)
    when 'README.md'
      extract_readme_insights(content)
    when 'api-reference.md'
      extract_api_insights(content)
    when 'patterns.md'
      extract_patterns_insights(content)
    else
      []
    end
  end

  def extract_readme_insights(content)
    insights = []
    insights << "Bot authentication with token" if content.include?('token')
    insights << "Message listening with bot.listen" if content.include?('listen')
    insights << "API access via bot.api" if content.include?('bot.api')
    insights << "Error handling with rescue blocks" if content.include?('rescue')
    insights
  end

  def extract_api_insights(content)
    insights = []
    insights << "Client class: Telegram::Bot::Client" if content.include?('Telegram::Bot::Client')
    insights << "Message types in Telegram::Bot::Types" if content.include?('Types::')
    insights << "Keyboard support (Reply/Inline)" if content.include?('KeyboardMarkup')
    insights << "Error classes for handling" if content.include?('Error')
    insights
  end

  def extract_patterns_insights(content)
    insights = []
    patterns = ['Command Handler', 'State Machine', 'Middleware', 'Service Layer', 'Repository']
    patterns.each do |pattern|
      insights << "#{pattern} pattern available" if content.include?(pattern)
    end
    insights
  end

  def extract_example_patterns(content)
    patterns = []
    patterns << "Command handling with case statements" if content.include?('case message.text')
    patterns << "Callback query processing" if content.include?('CallbackQuery')
    patterns << "File upload/download handling" if content.include?('photo|document')
    patterns << "Keyboard implementation" if content.include?('KeyboardMarkup')
    patterns << "Webhook endpoint setup" if content.include?('post|webhook')
    patterns
  end

  def load_learning_state
    default_state = {
      'telegram_bot_last_study' => nil,
      'ruby_llm_last_study' => nil
    }

    if File.exist?(LEARNING_STATE_FILE)
      JSON.parse(File.read(LEARNING_STATE_FILE))
    else
      FileUtils.mkdir_p(File.dirname(LEARNING_STATE_FILE))
      File.write(LEARNING_STATE_FILE, JSON.pretty_generate(default_state))
      default_state
    end
  end

  def update_learning_state(key, current_time)
    @learning_state[key] = current_time.iso8601
    File.write(LEARNING_STATE_FILE, JSON.pretty_generate(@learning_state))
    puts "\n💾 Learning state updated for #{key}"
  end

  # Ruby LLM specific methods
  def ruby_llm_related?(query, files)
    return true if query && ruby_llm_keywords_in_query?(query)
    return true if files && files.any? { |file| ruby_llm_keywords_in_file?(file) }
    false
  end

  def ruby_llm_keywords_in_query?(query)
    keywords = %w[
      ruby_llm llm ai assistant claude gpt
      tool function embedding generation model
      openai anthropic gemini acts_as_chat
      acts_as_message acts_as_tool_call
    ]

    query.downcase.match?(/#{keywords.join('|')}/)
  end

  def ruby_llm_keywords_in_file?(file)
    file_patterns = [
      /ruby_llm|llm|ai|chat|message/i,
      /app\/models\/chat\.rb/,
      /app\/models\/message\.rb/,
      /app\/models\/tool_call\.rb/,
      /config\/initializers\/ruby_llm\.rb/
    ]

    file_patterns.any? { |pattern| file.match?(pattern) }
  end

  def perform_ruby_llm_learning_sequence(query)
    puts "\n📚 **RUBY LLM LEARNING SEQUENCE**"

    sections = [
      {
        title: "Core Documentation",
        file: "docs/gems/ruby_llm/README.md",
        duration: "5 minutes",
        focus: "Basic setup, Rails integration, acts_as macros"
      },
      {
        title: "API Reference",
        file: "docs/gems/ruby_llm/api-reference.md",
        duration: "10 minutes",
        focus: "Complete API methods, responses, error handling"
      },
      {
        title: "Architecture Patterns",
        file: "docs/gems/ruby_llm/patterns.md",
        duration: "10 minutes",
        focus: "Design patterns, service layer, best practices"
      }
    ]

    sections.each do |section|
      study_ruby_llm_section(section)
    end

    study_ruby_llm_examples
    analyze_ruby_llm_implementation
    validate_ruby_llm_knowledge
  end

  def perform_ruby_llm_quick_refresher
    puts "\n⚡ **RUBY LLM QUICK REFRESHER**"

    # Quick review of key concepts
    key_points = [
      "✅ Ruby LLM provides unified interface for multiple AI providers",
      "✅ Rails integration with acts_as_chat, acts_as_message, acts_as_tool_call",
      "✅ Support for OpenAI, Anthropic, Gemini, DeepSeek, Mistral",
      "✅ Tool/function calling capabilities",
      "✅ Embeddings and image generation support",
      "✅ Streaming responses and error handling",
      "✅ Configuration management with anyway_config"
    ]

    key_points.each { |point| puts "   #{point}" }

    puts "\n🔍 **Quick implementation check:**"
    check_ruby_llm_implementation_status
  end

  def study_ruby_llm_section(section)
    puts "\n📖 **Studying: #{section[:title]}** (~#{section[:duration]})"
    puts "📁 File: #{section[:file]}"
    puts "🎯 Focus: #{section[:focus]}"

    if File.exist?(section[:file])
      content = File.read(section[:file])
      lines_count = content.lines.count
      puts "📄 Document length: #{lines_count} lines"

      # Extract key insights
      insights = extract_ruby_llm_section_insights(section[:file], content)
      if insights.any?
        puts "💡 Key insights:"
        insights.each { |insight| puts "   • #{insight}" }
      end
    else
      puts "⚠️  File not found: #{section[:file]}"
    end
  end

  def study_ruby_llm_examples
    puts "\n💻 **STUDYING RUBY LLM CODE EXAMPLES**"

    examples = [
      {
        file: "docs/gems/ruby_llm/examples/basic-chat.rb",
        description: "Basic chat implementation"
      },
      {
        file: "docs/gems/ruby_llm/examples/tool-calls.rb",
        description: "Function calling and tools"
      },
      {
        file: "docs/gems/ruby_llm/examples/configuration.rb",
        description: "Multi-provider configuration"
      }
    ]

    examples.each do |example|
      study_ruby_llm_example(example)
    end
  end

  def study_ruby_llm_example(example)
    puts "\n🔧 Example: #{example[:description]}"
    puts "📁 File: #{example[:file]}"

    if File.exist?(example[:file])
      content = File.read(example[:file])

      # Extract key patterns
      patterns = extract_ruby_llm_example_patterns(content)
      if patterns.any?
        puts "🏗️  Key patterns:"
        patterns.each { |pattern| puts "   • #{pattern}" }
      end
    else
      puts "⚠️  Example file not found"
    end
  end

  def analyze_ruby_llm_implementation
    puts "\n🔍 **ANALYZING CURRENT RUBY LLM IMPLEMENTATION**"

    # Check for existing ruby_llm code
    checks = [
      {
        name: "Models",
        pattern: "app/models/*",
        keywords: ["chat", "message", "tool_call", "acts_as"]
      },
      {
        name: "Configuration",
        pattern: "config/**/*",
        keywords: ["ruby_llm", "llm"]
      }
    ]

    checks.each do |check|
      analyze_ruby_llm_component(check)
    end
  end

  def analyze_ruby_llm_component(check)
    puts "\n📊 #{check[:name]}:"

    found_files = []

    Dir.glob(check[:pattern]).each do |file|
      next unless File.file?(file)

      content = File.read(file)
      if check[:keywords].any? { |keyword| content.downcase.include?(keyword) }
        found_files << file
      end
    end

    if found_files.any?
      puts "   Found #{found_files.length} relevant file(s):"
      found_files.each { |file| puts "   • #{file}" }
    else
      puts "   No relevant files found"
    end
  end

  def validate_ruby_llm_knowledge
    puts "\n🧠 **RUBY LLM KNOWLEDGE VALIDATION**"

    questions = [
      "What ruby_llm functionality currently exists?",
      "Which providers are configured and available?",
      "How are acts_as macros used in the project?",
      "What tool/function calling functionality exists?",
      "How is model selection currently handled?",
      "What is the current error handling strategy?"
    ]

    puts "\n📋 Self-assessment questions (Claude should be able to answer these):"
    questions.each_with_index do |question, index|
      puts "   #{index + 1}. #{question}"
    end

    puts "\n✅ Claude must validate understanding before proceeding"
  end

  def display_ruby_llm_checklist
    puts "\n📋 **RUBY LLM PRE-WORK CHECKLIST**"
    puts "Please ensure Claude completes this checklist:"
    puts "📄 Full checklist available: .claude/ruby_llm-checklist.md"

    checklist_items = [
      "□ Documentation study completed",
      "□ Current implementation analyzed",
      "□ Knowledge validation passed",
      "□ Task-specific preparation complete",
      "□ Ready to proceed: Yes/No"
    ]

    checklist_items.each { |item| puts "   #{item}" }
  end

  def check_ruby_llm_implementation_status
    # Quick checks for common implementation indicators
    checks = [
      { file: "Gemfile", pattern: /ruby_llm/ },
      { file: "app/models/chat.rb", pattern: /acts_as_chat/ },
      { file: "config/initializers/ruby_llm.rb", pattern: /RubyLLM\.configure/ }
    ]

    checks.each do |check|
      if File.exist?(check[:file])
        content = File.read(check[:file])
        if content.match?(check[:pattern])
          puts "   ✅ Found ruby_llm references in #{check[:file]}"
        end
      end
    end
  end

  def extract_ruby_llm_section_insights(file_path, content)
    case File.basename(file_path)
    when 'README.md'
      extract_ruby_llm_readme_insights(content)
    when 'api-reference.md'
      extract_ruby_llm_api_insights(content)
    when 'patterns.md'
      extract_ruby_llm_patterns_insights(content)
    else
      []
    end
  end

  def extract_ruby_llm_readme_insights(content)
    insights = []
    insights << "Rails integration with acts_as macros" if content.include?('acts_as')
    insights << "Multi-provider support" if content.include?('openai|anthropic|gemini')
    insights << "Chat functionality" if content.include?('RubyLLM.chat')
    insights << "Embeddings support" if content.include?('RubyLLM.embed')
    insights << "Image generation" if content.include?('RubyLLM.paint')
    insights << "Tool calling" if content.include?('tool|function')
    insights
  end

  def extract_ruby_llm_api_insights(content)
    insights = []
    insights << "Chat API methods" if content.include?('RubyLLM.chat')
    insights << "Embedding API" if content.include?('RubyLLM.embed')
    insights << "Image generation API" if content.include?('RubyLLM.paint')
    insights << "Response objects" if content.include?('response\.')
    insights << "Error handling" if content.include?('Error|Exception')
    insights << "Configuration options" if content.include?('configure')
    insights
  end

  def extract_ruby_llm_patterns_insights(content)
    insights = []
    patterns = ['Service Layer', 'Repository', 'Caching', 'Error Handling', 'Model Selection']
    patterns.each do |pattern|
      insights << "#{pattern} pattern available" if content.include?(pattern)
    end
    insights
  end

  def extract_ruby_llm_example_patterns(content)
    patterns = []
    patterns << "Basic chat usage" if content.include?('RubyLLM.chat.new')
    patterns << "Tool calling implementation" if content.include?('tools:|tool_calls')
    patterns << "Multi-provider configuration" if content.include?('openai_api_key|anthropic_api_key')
    patterns << "Streaming responses" if content.include?('stream: true')
    patterns << "Embedding generation" if content.include?('RubyLLM.embed')
    patterns << "Image generation" if content.include?('RubyLLM.paint')
    patterns
  end
end

# Run the hook if this script is executed directly
if __FILE__ == $0
  query = ARGV[0] || "telegram bot implementation"
  files = ARGV[1..-1] || []

  hook = PreWorkHook.new
  hook.run(query, files)
end