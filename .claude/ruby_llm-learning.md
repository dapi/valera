# Ruby LLM Learning Protocol for Claude

## 🎯 Objective
This document provides Claude with a structured learning protocol for ruby_llm functionality before analyzing, planning, or modifying any LLM-related code.

## 📚 Learning Sequence

### Phase 1: Pre-Task Knowledge Check
Before ANY work on ruby_llm related code, Claude MUST:

1. **Check Last Study Time**: Verify when ruby_llm documentation was last studied
2. **Refresh if Needed**: If > 24 hours since last study, complete full learning sequence
3. **Context Load**: Load current ruby_llm implementation state

### Phase 2: Core Documentation Study
Always study in this specific order:

#### 2.1 Main Documentation (5 minutes)
- Read: `docs/gems/ruby_llm/README.md`
- Focus: Core concepts, configuration, acts_as macros, basic chat usage
- Key takeaways: Setup, providers, models, Rails integration

#### 2.2 API Reference (10 minutes)
- Read: `docs/gems/ruby_llm/api-reference.md`
- Focus: Complete API methods, response objects, error handling
- Key takeaways: Chat methods, embedding, image generation, tool calls

#### 2.3 Architecture Patterns (10 minutes)
- Read: `docs/gems/ruby_llm/patterns.md`
- Focus: Design patterns, best practices, service layer, caching
- Key takeaways: Service patterns, error handling, performance optimization

#### 2.4 Code Examples (15 minutes)
- Study: `docs/gems/ruby_llm/examples/basic-chat.rb`
  - Focus: Basic chat implementation, model selection
- Study: `docs/gems/ruby_llm/examples/tool-calls.rb`
  - Focus: Function calling, tool definition and execution
- Study: `docs/gems/ruby_llm/examples/configuration.rb`
  - Focus: Multi-provider setup, environment configuration

### Phase 3: Current Implementation Analysis
After documentation study:

#### 3.1 Current Code Review
- Examine: `app/models/chat.rb` - Understand acts_as_chat usage
- Examine: `app/models/message.rb` - Understand acts_as_message usage
- Examine: `app/models/tool_call.rb` - Understand acts_as_tool_call usage
- Examine: `app/models/model.rb` - Model configuration management

#### 3.2 Configuration Analysis
- Review: `config/initializers/ruby_llm.rb` - Current provider setup
- Review: `config/configs/application_config.rb` - Configuration management
- Check: Environment variables and API keys
- Identify: Available models and providers

#### 3.3 Database Schema Analysis
- Review: `db/schema.rb` for ruby_llm related tables
- Check: `db/migrate/` for ruby_llm migrations
- Identify: Current data structures and relationships

### Phase 4: Knowledge Validation
Before proceeding with task:

#### 4.1 Self-Assessment Questions
Claude MUST be able to answer:
1. What ruby_llm models are currently implemented?
2. Which providers are configured and available?
3. How are acts_as macros used in the project?
4. What tool/function calling functionality exists?
5. How is model selection currently handled?
6. What is the current error handling strategy?
7. How are embeddings and image generation used?

#### 4.2 Implementation State Summary
Create brief summary of:
- Current ruby_llm functionality
- Configured providers and models
- Architecture patterns in use
- Integration points with Rails app

## 🔧 Task-Specific Learning Triggers

### Before Planning LLM Features:
- Study: `patterns.md` → relevant service patterns
- Study: `examples/` → similar implementations
- Analyze: Current acts_as implementation
- Review: Current provider configuration

### Before Debugging LLM Issues:
- Study: `api-reference.md` → error codes/handling
- Study: `examples/` → troubleshooting patterns
- Analyze: Current error logs and configuration
- Review: Provider-specific issues

### Before Adding New LLM Functionality:
- Study: `README.md` → new features overview
- Study: `patterns.md` → integration patterns
- Study: `examples/configuration.rb` → provider setup
- Analyze: Current architecture for compatibility

### Before Modifying LLM Configuration:
- Study: `examples/configuration.rb` → configuration patterns
- Analyze: Current provider setup
- Review: Environment variable usage
- Study: `api-reference.md` → configuration options

### Before Implementing Tool Calls:
- Study: `examples/tool-calls.rb` → function calling patterns
- Study: `api-reference.md` → tool call API
- Analyze: Current tool_call model usage
- Review: Error handling for tool execution

## 📋 Learning Checklist Template

Claude should use this checklist before ANY ruby_llm work:

```
🤖 Ruby LLM Learning Checklist

□ Documentation Study Completed:
  □ README.md (Core concepts + Rails integration)
  □ api-reference.md (Complete API + methods)
  □ patterns.md (Architecture patterns)
  □ examples/ (Code examples + configurations)

□ Current Implementation Analyzed:
  □ Chat model and acts_as_chat reviewed
  □ Message model and acts_as_message examined
  □ ToolCall model and acts_as_tool_call checked
  □ Configuration files reviewed
  □ Database schema understood

□ Knowledge Validation:
  □ Can explain current LLM implementation
  □ Can identify available providers and models
  □ Can locate appropriate API methods
  □ Understands acts_as macro usage
  □ Can handle tool/function calls

□ Task-Specific Preparation:
  □ Studied relevant sections for task
  □ Identified applicable patterns
  □ Located similar examples
  □ Understood current limitations

Learning Time: ___ minutes
Last Study: ___
Ready to proceed: Yes/No
```

## 🔄 Knowledge Refresh Schedule

### Mandatory Refresh Intervals:
- **Every 24 hours** for active LLM development
- **Every 7 days** for maintenance tasks
- **Before any major changes** regardless of timing

### Triggers for Immediate Refresh:
- Encountering unexpected API errors
- Adding new LLM providers or models
- Implementing new tool calling functionality
- Performance optimization tasks
- Configuration changes

## 💡 Integration with Development Workflow

### When User Requests LLM Work:
1. Claude automatically starts learning protocol
2. Documents study completion
3. Provides implementation state summary
4. Proceeds with task analysis and planning

### Continuous Learning:
- Keep track of what was studied when
- Incrementally build on existing knowledge
- Focus study sessions on task-relevant sections
- Update mental model based on current implementation

## 🎓 Success Criteria

Claude successfully completed learning when:
- Can explain ruby_llm architecture in project
- Can reference specific API methods for common tasks
- Can identify appropriate patterns for given scenarios
- Can locate and adapt relevant examples
- Can articulate current implementation state
- Can identify integration points and dependencies
- Understands acts_as macro usage thoroughly
- Can handle tool/function calling implementation

This ensures Claude has comprehensive, current knowledge before making any changes to LLM functionality.