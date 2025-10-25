#!/usr/bin/env ruby

# Context Processor for Claude - Automatic Learning System
# This script automatically triggers learning protocols when Claude detects telegram-related work

require 'json'
require 'fileutils'
require 'time'

class ContextProcessor
  LEARNING_STATE_FILE = File.expand_path('~/.claude/learning_state.json')
  TELEGRAM_LEARNING_FILE = File.expand_path('../telegram-bot-learning.md', __dir__)

  def initialize
    @learning_state = load_learning_state
  end

  def process_context(query, files_mentioned, task_type)
    # Detect if this is telegram-related work
    if telegram_related_work?(query, files_mentioned)
      ensure_telegram_knowledge_current(query, task_type)
    end
  end

  private

  def process_context(query, files_mentioned, task_type)
    # Detect if this is telegram-related work
    if telegram_related_work?(query, files_mentioned)
      ensure_telegram_knowledge_current(query, task_type)
    end

    # Detect if this is ruby_llm-related work
    if ruby_llm_related_work?(query, files_mentioned)
      ensure_ruby_llm_knowledge_current(query, task_type)
    end
  end

  private

  def telegram_related_work?(query, files_mentioned)
    telegram_keywords = [
      'telegram', 'bot', 'webhook', 'chat', 'message',
      'inline', 'callback', 'keyboard', 'button',
      'tg_', 'telegr', 'bot_token'
    ]

    # Check query for telegram keywords
    query_match = query.downcase.match?(/#{telegram_keywords.join('|')}/)

    # Check mentioned files for telegram-related paths
    file_match = files_mentioned.any? do |file|
      file.match?(/telegram|bot|webhook|chat/i) ||
      file.include?('app/models/chat') ||
      file.include?('app/models/message')
    end

    query_match || file_match
  end

  def ruby_llm_related_work?(query, files_mentioned)
    ruby_llm_keywords = [
      'ruby_llm', 'llm', 'ai', 'assistant', 'claude', 'gpt',
      'tool', 'function', 'embedding', 'generation', 'model',
      'openai', 'anthropic', 'gemini', 'acts_as_chat',
      'acts_as_message', 'acts_as_tool_call'
    ]

    # Check query for ruby_llm keywords
    query_match = query.downcase.match?(/#{ruby_llm_keywords.join('|')}/)

    # Check mentioned files for ruby_llm-related paths
    file_match = files_mentioned.any? do |file|
      file.match?(/ruby_llm|llm|ai|chat|message|tool/i) ||
      file.include?('app/models/chat.rb') ||
      file.include?('app/models/message.rb') ||
      file.include?('app/models/tool_call.rb') ||
      file.include?('config/initializers/ruby_llm.rb')
    end

    query_match || file_match
  end

  def ensure_telegram_knowledge_current(query, task_type)
    last_study = @learning_state['telegram_bot_last_study']
    current_time = Time.now

    # Check if refresh is needed
    needs_refresh = need_learning_refresh?(last_study, current_time, task_type)

    if needs_refresh
      trigger_telegram_learning_protocol(query, task_type)
      update_learning_state('telegram_bot_last_study', current_time)
    end
  end

  def need_learning_refresh?(last_study, current_time, task_type)
    return true if last_study.nil?

    last_study_time = Time.parse(last_study)
    hours_since_study = (current_time - last_study_time) / 3600

    # Different refresh intervals based on task type
    case task_type
    when :development, :major_changes
      hours_since_study > 1  # 1 hour for active development
    when :debugging, :optimization
      hours_since_study > 6  # 6 hours for debugging
    when :maintenance
      hours_since_study > 24 # 24 hours for maintenance
    else
      hours_since_study > 24 # Default 24 hours
    end
  end

  def trigger_telegram_learning_protocol(query, task_type)
    puts "\n🤖 **Telegram Bot Learning Protocol Activated**"
    puts "📚 Detected telegram-related work: #{task_type}"
    puts "🔍 Query: #{query[0..100]}#{'...' if query.length > 100}"
    puts "\n⏰ **Starting Learning Sequence...**"

    # Phase 1: Documentation Study
    study_documentation

    # Phase 2: Current Implementation Analysis
    analyze_current_implementation

    # Phase 3: Knowledge Validation
    validate_knowledge

    # Phase 4: Task-Specific Preparation
    prepare_for_task(query, task_type)

    puts "\n✅ **Learning Protocol Complete**"
    puts "🚀 Ready to proceed with telegram-related task"
  end

  def study_documentation
    puts "\n📖 **Phase 1: Documentation Study**"

    docs_to_study = [
      {
        file: 'docs/gems/telegram-bot/README.md',
        title: 'Core Documentation',
        duration: '5 minutes'
      },
      {
        file: 'docs/gems/telegram-bot/api-reference.md',
        title: 'API Reference',
        duration: '10 minutes'
      },
      {
        file: 'docs/gems/telegram-bot/patterns.md',
        title: 'Architecture Patterns',
        duration: '10 minutes'
      }
    ]

    docs_to_study.each do |doc|
      study_document(doc)
    end

    # Study examples
    study_examples
  end

  def study_document(doc)
    puts "\n📄 Studying: #{doc[:title]} (~#{doc[:duration]})"
    puts "📁 File: #{doc[:file]}"

    if File.exist?(doc[:file])
      content = File.read(doc[:file])

      # Extract key concepts based on document type
      key_concepts = extract_key_concepts(doc[:file], content)

      puts "💡 Key concepts identified:"
      key_concepts.each { |concept| puts "   • #{concept}" }
    else
      puts "⚠️  File not found: #{doc[:file]}"
    end
  end

  def study_examples
    puts "\n💻 **Studying Code Examples**"

    examples = [
      {
        file: 'docs/gems/telegram-bot/examples/advanced-handlers.rb',
        focus: 'Complex scenarios, file handling'
      }
    ]

    examples.each do |example|
      study_example(example)
    end
  end

  def study_example(example)
    puts "\n🔧 Example: #{example[:focus]}"
    puts "📁 File: #{example[:file]}"

    if File.exist?(example[:file])
      content = File.read(example[:file])

      # Extract key patterns from example
      patterns = extract_patterns_from_example(content)

      puts "🏗️  Key patterns:"
      patterns.each { |pattern| puts "   • #{pattern}" }
    else
      puts "⚠️  Example file not found"
    end
  end

  def analyze_current_implementation
    puts "\n🔍 **Phase 2: Current Implementation Analysis**"

    # Analyze models
    analyze_models

    # Analyze controllers
    analyze_controllers

    # Analyze configuration
    analyze_configuration

    # Analyze database schema
    analyze_database
  end

  def analyze_models
    puts "\n📊 **Analyzing Models**"

    model_files = Dir.glob('app/models/*').select do |file|
      File.read(file).match?(/telegram|chat|message|bot/i)
    end

    if model_files.any?
      puts "Found telegram-related models:"
      model_files.each { |file| puts "   • #{file}" }
    else
      puts "No telegram-related models found"
    end
  end

  def analyze_controllers
    puts "\n🎮 **Analyzing Controllers**"

    controller_files = Dir.glob('app/controllers/*').select do |file|
      File.read(file).match?(/telegram|webhook|bot/i)
    end

    if controller_files.any?
      puts "Found telegram-related controllers:"
      controller_files.each { |file| puts "   • #{file}" }
    else
      puts "No telegram-related controllers found"
    end
  end

  def analyze_configuration
    puts "\n⚙️  **Analyzing Configuration**"

    config_files = [
      'config/initializers/ruby_llm.rb',
      'config/initializers/telegram_bot.rb',
      'config/configs/application_config.rb'
    ]

    config_files.select! { |file| File.exist?(file) }

    if config_files.any?
      puts "Found relevant configuration files:"
      config_files.each { |file| puts "   • #{file}" }
    else
      puts "No telegram-specific configuration files found"
    end
  end

  def analyze_database
    puts "\n🗄️  **Analyzing Database Schema**"

    if File.exist?('db/schema.rb')
      schema_content = File.read('db/schema.rb')

      telegram_tables = schema_content.scan(/create_table\s+"([^"]*telegram|[^"]*chat|[^"]*message[^"]*)"/i).flatten

      if telegram_tables.any?
        puts "Found telegram-related tables:"
        telegram_tables.each { |table| puts "   • #{table}" }
      else
        puts "No telegram-related tables found in schema"
      end
    else
      puts "Database schema file not found"
    end
  end

  def validate_knowledge
    puts "\n🧠 **Phase 3: Knowledge Validation**"

    validation_questions = [
      "What telegram bot methods are currently implemented?",
      "What is the current authentication setup?",
      "What message types are supported?",
      "How are webhooks currently configured?",
      "What is the current error handling strategy?"
    ]

    puts "📋 Self-assessment questions:"
    validation_questions.each_with_index do |question, index|
      puts "   #{index + 1}. #{question}"
    end

    puts "\n✅ Claude should be able to answer these questions before proceeding"
  end

  def prepare_for_task(query, task_type)
    puts "\n🎯 **Phase 4: Task-Specific Preparation**"
    puts "📝 Task: #{task_type}"
    puts "🔍 Query focus: #{extract_task_focus(query)}"

    # Suggest specific sections to review based on task
    suggestions = get_task_specific_suggestions(task_type, query)

    if suggestions.any?
      puts "\n💡 Recommended sections to review:"
      suggestions.each { |suggestion| puts "   • #{suggestion}" }
    end
  end

  def extract_key_concepts(file_path, content)
    case File.basename(file_path)
    when 'README.md'
      extract_concepts_from_readme(content)
    when 'api-reference.md'
      extract_concepts_from_api_ref(content)
    when 'patterns.md'
      extract_concepts_from_patterns(content)
    else
      ['General documentation concepts']
    end
  end

  def extract_concepts_from_readme(content)
    concepts = []
    concepts << 'Basic bot setup' if content.include?('bot = Telegram::Bot::Client.new')
    concepts << 'Message handling' if content.include?('bot.listen')
    concepts << 'API methods' if content.include?('bot.api')
    concepts << 'Error handling' if content.include?('rescue')
    concepts.uniq
  end

  def extract_concepts_from_api_ref(content)
    concepts = []
    concepts << 'Client configuration' if content.include?('Telegram::Bot::Client')
    concepts << 'Message types' if content.include?('Telegram::Bot::Types::')
    concepts << 'API methods' if content.include?('send_message|send_photo|send_document')
    concepts << 'Keyboard types' if content.include?('ReplyKeyboardMarkup|InlineKeyboardMarkup')
    concepts << 'Error handling' if content.include?('ResponseError|APIError')
    concepts.uniq
  end

  def extract_concepts_from_patterns(content)
    concepts = []
    concepts << 'Command handler pattern' if content.include?('CommandHandler')
    concepts << 'State machine pattern' if content.include?('UserStateMachine')
    concepts << 'Middleware pattern' if content.include?('MessageMiddleware')
    concepts << 'Service layer pattern' if content.include?('Service')
    concepts << 'Repository pattern' if content.include?('Repository')
    concepts.uniq
  end

  def extract_patterns_from_example(content)
    patterns = []
    patterns << 'Command handling' if content.include?('case message.text')
    patterns << 'Callback queries' if content.include?('CallbackQuery')
    patterns << 'File handling' if content.include?('photo|document|video')
    patterns << 'Error handling' if content.include?('rescue')
    patterns << 'Keyboard usage' if content.include?('ReplyKeyboardMarkup|InlineKeyboardMarkup')
    patterns << 'Webhook setup' if content.include?('webhook|post')
    patterns.uniq
  end

  def extract_task_focus(query)
    keywords = {
      'add' => 'Adding new functionality',
      'fix' => 'Bug fixing',
      'implement' => 'New implementation',
      'update' => 'Updating existing code',
      'create' => 'Creating new features',
      'debug' => 'Debugging issues',
      'refactor' => 'Code refactoring'
    }

    keywords.each { |key, value| return value if query.downcase.include?(key) }
    'General telegram work'
  end

  def get_task_specific_suggestions(task_type, query)
    suggestions = []

    case task_type
    when :development, :major_changes
      suggestions << 'Architecture patterns for scalability'
      suggestions << 'Error handling best practices'
      suggestions << 'Testing strategies'
    when :debugging
      suggestions << 'API error codes and handling'
      suggestions << 'Common debugging patterns'
      suggestions << 'Logging and monitoring'
    when :maintenance
      suggestions << 'Configuration management'
      suggestions << 'Performance optimization'
      suggestions << 'Security considerations'
    end

    # Add query-specific suggestions
    if query.downcase.include?('webhook')
      suggestions << 'Webhook setup and configuration'
    elsif query.downcase.include?('command')
      suggestions << 'Command handling patterns'
    elsif query.downcase.include?('message')
      suggestions << 'Message type handling'
    elsif query.downcase.include?('keyboard')
      suggestions << 'Keyboard implementation patterns'
    end

    suggestions.uniq
  end

  def ensure_ruby_llm_knowledge_current(query, task_type)
    last_study = @learning_state['ruby_llm_last_study']
    current_time = Time.now

    # Check if refresh is needed
    needs_refresh = need_learning_refresh?(last_study, current_time, task_type)

    if needs_refresh
      trigger_ruby_llm_learning_protocol(query, task_type)
      update_learning_state('ruby_llm_last_study', current_time)
    end
  end

  def trigger_ruby_llm_learning_protocol(query, task_type)
    puts "\n🤖 **Ruby LLM Learning Protocol Activated**"
    puts "📚 Detected ruby_llm-related work: #{task_type}"
    puts "🔍 Query: #{query[0..100]}#{'...' if query.length > 100}"
    puts "\n⏰ **Starting Learning Sequence...**"

    # Phase 1: Documentation Study
    study_ruby_llm_documentation

    # Phase 2: Current Implementation Analysis
    analyze_ruby_llm_implementation

    # Phase 3: Knowledge Validation
    validate_ruby_llm_knowledge

    # Phase 4: Task-Specific Preparation
    prepare_for_ruby_llm_task(query, task_type)

    puts "\n✅ **Ruby LLM Learning Protocol Complete**"
    puts "🚀 Ready to proceed with ruby_llm-related task"
  end

  def study_ruby_llm_documentation
    puts "\n📖 **Phase 1: Ruby LLM Documentation Study**"

    docs_to_study = [
      {
        file: 'docs/gems/ruby_llm/README.md',
        title: 'Core Documentation',
        duration: '5 minutes'
      },
      {
        file: 'docs/gems/ruby_llm/api-reference.md',
        title: 'API Reference',
        duration: '10 minutes'
      },
      {
        file: 'docs/gems/ruby_llm/patterns.md',
        title: 'Architecture Patterns',
        duration: '10 minutes'
      }
    ]

    docs_to_study.each do |doc|
      study_ruby_llm_document(doc)
    end

    # Study examples
    study_ruby_llm_examples
  end

  def study_ruby_llm_document(doc)
    puts "\n📄 Studying: #{doc[:title]} (~#{doc[:duration]})"
    puts "📁 File: #{doc[:file]}"

    if File.exist?(doc[:file])
      content = File.read(doc[:file])

      # Extract key concepts based on document type
      key_concepts = extract_ruby_llm_key_concepts(doc[:file], content)

      puts "💡 Key concepts identified:"
      key_concepts.each { |concept| puts "   • #{concept}" }
    else
      puts "⚠️  File not found: #{doc[:file]}"
    end
  end

  def study_ruby_llm_examples
    puts "\n💻 **Studying Ruby LLM Code Examples**"

    examples = [
      {
        file: 'docs/gems/ruby_llm/examples/basic-chat.rb',
        focus: 'Basic chat implementation'
      },
      {
        file: 'docs/gems/ruby_llm/examples/tool-calls.rb',
        focus: 'Function calling and tools'
      },
      {
        file: 'docs/gems/ruby_llm/examples/configuration.rb',
        focus: 'Multi-provider configuration'
      }
    ]

    examples.each do |example|
      study_ruby_llm_example(example)
    end
  end

  def study_ruby_llm_example(example)
    puts "\n🔧 Example: #{example[:focus]}"
    puts "📁 File: #{example[:file]}"

    if File.exist?(example[:file])
      content = File.read(example[:file])

      # Extract key patterns from example
      patterns = extract_ruby_llm_patterns_from_example(content)

      puts "🏗️  Key patterns:"
      patterns.each { |pattern| puts "   • #{pattern}" }
    else
      puts "⚠️  Example file not found"
    end
  end

  def analyze_ruby_llm_implementation
    puts "\n🔍 **Phase 2: Current Ruby LLM Implementation Analysis**"

    # Analyze models
    analyze_ruby_llm_models

    # Analyze configuration
    analyze_ruby_llm_configuration

    # Analyze database schema
    analyze_ruby_llm_database
  end

  def analyze_ruby_llm_models
    puts "\n📊 **Analyzing Ruby LLM Models**"

    model_files = [
      'app/models/chat.rb',
      'app/models/message.rb',
      'app/models/tool_call.rb',
      'app/models/model.rb'
    ]

    model_files.select! { |file| File.exist?(file) }

    if model_files.any?
      puts "Found ruby_llm-related models:"
      model_files.each { |file| puts "   • #{file}" }

      model_files.each do |file|
        content = File.read(file)
        if content.include?('acts_as_')
          macros = content.scan(/acts_as_\w+/)
          puts "   #{File.basename(file)} uses: #{macros.join(', ')}"
        end
      end
    else
      puts "No ruby_llm-related models found"
    end
  end

  def analyze_ruby_llm_configuration
    puts "\n⚙️  **Analyzing Ruby LLM Configuration**"

    config_files = [
      'config/initializers/ruby_llm.rb',
      'config/configs/application_config.rb'
    ]

    config_files.select! { |file| File.exist?(file) }

    if config_files.any?
      puts "Found ruby_llm configuration files:"
      config_files.each { |file| puts "   • #{file}" }
    else
      puts "No ruby_llm configuration files found"
    end
  end

  def analyze_ruby_llm_database
    puts "\n🗄️  **Analyzing Ruby LLM Database Schema**"

    if File.exist?('db/schema.rb')
      schema_content = File.read('db/schema.rb')

      ruby_llm_tables = schema_content.scan(/create_table\s+"([^"]*chats|[^"]*messages|[^"]*tool_calls|[^"]*models[^"]*)"/i).flatten

      if ruby_llm_tables.any?
        puts "Found ruby_llm-related tables:"
        ruby_llm_tables.each { |table| puts "   • #{table}" }
      else
        puts "No ruby_llm-related tables found in schema"
      end
    else
      puts "Database schema file not found"
    end
  end

  def validate_ruby_llm_knowledge
    puts "\n🧠 **Phase 3: Ruby LLM Knowledge Validation**"

    validation_questions = [
      "What ruby_llm models are currently implemented?",
      "Which providers are configured and available?",
      "How are acts_as macros used in the project?",
      "What tool/function calling functionality exists?",
      "How is model selection currently handled?",
      "What is the current error handling strategy?"
    ]

    puts "📋 Self-assessment questions:"
    validation_questions.each_with_index do |question, index|
      puts "   #{index + 1}. #{question}"
    end

    puts "\n✅ Claude should be able to answer these questions before proceeding"
  end

  def prepare_for_ruby_llm_task(query, task_type)
    puts "\n🎯 **Phase 4: Ruby LLM Task-Specific Preparation**"
    puts "📝 Task: #{task_type}"
    puts "🔍 Query focus: #{extract_ruby_llm_task_focus(query)}"

    # Suggest specific sections to review based on task
    suggestions = get_ruby_llm_task_specific_suggestions(task_type, query)

    if suggestions.any?
      puts "\n💡 Recommended sections to review:"
      suggestions.each { |suggestion| puts "   • #{suggestion}" }
    end
  end

  def extract_ruby_llm_key_concepts(file_path, content)
    case File.basename(file_path)
    when 'README.md'
      extract_ruby_llm_concepts_from_readme(content)
    when 'api-reference.md'
      extract_ruby_llm_concepts_from_api_ref(content)
    when 'patterns.md'
      extract_ruby_llm_concepts_from_patterns(content)
    else
      ['General ruby_llm concepts']
    end
  end

  def extract_ruby_llm_concepts_from_readme(content)
    concepts = []
    concepts << 'acts_as macros for Rails integration' if content.include?('acts_as')
    concepts << 'Multi-provider support' if content.include?('openai|anthropic|gemini')
    concepts << 'Chat functionality' if content.include?('RubyLLM.chat')
    concepts << 'Embeddings support' if content.include?('RubyLLM.embed')
    concepts << 'Image generation' if content.include?('RubyLLM.paint')
    concepts << 'Tool calling' if content.include?('tool|function')
    concepts.uniq
  end

  def extract_ruby_llm_concepts_from_api_ref(content)
    concepts = []
    concepts << 'Chat API methods' if content.include?('RubyLLM.chat')
    concepts << 'Embedding API' if content.include?('RubyLLM.embed')
    concepts << 'Image generation API' if content.include?('RubyLLM.paint')
    concepts << 'Response objects' if content.include?('response\.')
    concepts << 'Error handling' if content.include?('Error|Exception')
    concepts << 'Configuration options' if content.include?('configure')
    concepts.uniq
  end

  def extract_ruby_llm_concepts_from_patterns(content)
    concepts = []
    concepts << 'Service layer pattern' if content.include?('Service')
    concepts << 'Repository pattern' if content.include?('Repository')
    concepts << 'Caching patterns' if content.include?('Cache')
    concepts << 'Error handling patterns' if content.include?('Error')
    concepts << 'Performance optimization' if content.include?('Performance')
    concepts << 'Model selection strategies' if content.include?('ModelSelection')
    concepts.uniq
  end

  def extract_ruby_llm_patterns_from_example(content)
    patterns = []
    patterns << 'Basic chat usage' if content.include?('RubyLLM.chat.new')
    patterns << 'Tool calling implementation' if content.include?('tools:|tool_calls')
    patterns << 'Multi-provider configuration' if content.include?('openai_api_key|anthropic_api_key')
    patterns << 'Streaming responses' if content.include?('stream: true')
    patterns << 'Embedding generation' if content.include?('RubyLLM.embed')
    patterns << 'Image generation' if content.include?('RubyLLM.paint')
    patterns.uniq
  end

  def extract_ruby_llm_task_focus(query)
    keywords = {
      'chat' => 'Chat functionality implementation',
      'tool' => 'Tool/function calling implementation',
      'embedding' => 'Embedding generation and usage',
      'image' => 'Image generation functionality',
      'configure' => 'Configuration and setup',
      'model' => 'Model selection and management',
      'error' => 'Error handling and debugging',
      'performance' => 'Performance optimization'
    }

    keywords.each { |key, value| return value if query.downcase.include?(key) }
    'General ruby_llm work'
  end

  def get_ruby_llm_task_specific_suggestions(task_type, query)
    suggestions = []

    case task_type
    when :development, :major_changes
      suggestions << 'Architecture patterns for scalability'
      suggestions << 'Service layer implementation'
      suggestions << 'Error handling best practices'
    when :debugging
      suggestions << 'API error codes and handling'
      suggestions << 'Common debugging patterns'
      suggestions << 'Configuration troubleshooting'
    when :maintenance
      suggestions << 'Configuration management'
      suggestions << 'Performance optimization'
      suggestions << 'Model selection strategies'
    end

    # Add query-specific suggestions
    if query.downcase.include?('tool')
      suggestions << 'Function calling patterns'
    elsif query.downcase.include?('chat')
      suggestions << 'Chat implementation patterns'
    elsif query.downcase.include?('configure')
      suggestions << 'Multi-provider configuration'
    elsif query.downcase.include?('embedding')
      suggestions << 'Embedding usage patterns'
    end

    suggestions.uniq
  end

  def load_learning_state
    default_state = {
      'telegram_bot_last_study' => nil,
      'ruby_llm_last_study' => nil
    }

    if File.exist?(LEARNING_STATE_FILE)
      JSON.parse(File.read(LEARNING_STATE_FILE))
    else
      # Create directory and file
      FileUtils.mkdir_p(File.dirname(LEARNING_STATE_FILE))
      File.write(LEARNING_STATE_FILE, JSON.pretty_generate(default_state))
      default_state
    end
  end

  def update_learning_state(key, value)
    @learning_state[key] = value.iso8601
    File.write(LEARNING_STATE_FILE, JSON.pretty_generate(@learning_state))
  end
end

# Usage example (this would be called by Claude's context processing)
if __FILE__ == $0
  processor = ContextProcessor.new

  # Example usage
  processor.process_context(
    "Add new telegram command for weather updates",
    ["app/controllers/telegram_controller.rb"],
    :development
  )
end