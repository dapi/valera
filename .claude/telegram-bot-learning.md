# Telegram Bot Learning Protocol for Claude

## 🎯 Objective
This document provides Claude with a structured learning protocol for telegram-bot functionality before analyzing, planning, or modifying any telegram-related code.

## 📚 Learning Sequence

### Phase 1: Pre-Task Knowledge Check
Before ANY work on telegram-bot related code, Claude MUST:

1. **Check Last Study Time**: Verify when telegram-bot documentation was last studied
2. **Refresh if Needed**: If > 24 hours since last study, complete full learning sequence
3. **Context Load**: Load current telegram-bot implementation state

### Phase 2: Core Documentation Study
Always study in this specific order:

#### 2.1 Main Documentation (5 minutes)
- Read: `docs/gems/telegram-bot/README.md`
- Focus: Core concepts, basic setup, message types
- Key takeaways: API structure, authentication, basic patterns

#### 2.2 API Reference (10 minutes)
- Read: `docs/gems/telegram-bot/api-reference.md`
- Focus: Complete API methods, parameters, return types
- Key takeaways: Method signatures, error handling, limits

#### 2.3 Architecture Patterns (10 minutes)
- Read: `docs/gems/telegram-bot/patterns.md`
- Focus: Design patterns, best practices, scalability
- Key takeaways: State management, error handling, testing

#### 2.4 Code Examples (15 minutes)
- Study: `docs/gems/telegram-bot/examples/advanced-handlers.rb`
  - Focus: Complex scenarios, file handling, state

### Phase 3: Current Implementation Analysis
After documentation study:

#### 3.1 Current Code Review
- Examine: `app/models/` - Look for existing telegram-related models
- Examine: `app/controllers/` - Find telegram controllers/endpoints
- Examine: `config/initializers/` - Check telegram configuration
- Examine: `lib/` - Look for telegram services/workers

#### 3.2 Database Schema Analysis
- Review: `db/schema.rb` for telegram-related tables
- Check: `db/migrate/` for telegram migrations
- Identify: Current data structures and relationships

#### 3.3 Configuration Analysis
- Review: `config/` files for telegram settings
- Check: Environment variables and secrets
- Identify: Current authentication and webhook setup

### Phase 4: Knowledge Validation
Before proceeding with task:

#### 4.1 Self-Assessment Questions
Claude MUST be able to answer:
1. What telegram bot methods are currently implemented?
2. What is the current authentication setup?
3. What message types are supported?
4. How are webhooks currently configured?
5. What is the current error handling strategy?
6. What testing patterns are in place?

#### 4.2 Implementation State Summary
Create brief summary of:
- Current telegram functionality
- Identified gaps or issues
- Architecture patterns in use
- Integration points with Rails app

## 🔧 Task-Specific Learning Triggers

### Before Planning Telegram Features:
- Study: `patterns.md` → relevant patterns
- Study: `examples/` → similar implementations
- Analyze: Current implementation state

### Before Debugging Telegram Issues:
- Study: `api-reference.md` → error codes/handling
- Study: `examples/` → troubleshooting patterns
- Analyze: Current error logs and configuration

### Before Adding New Telegram Functionality:
- Study: `README.md` → new features overview
- Study: `patterns.md` → integration patterns
- Study: `examples/` → similar implementations
- Analyze: Current architecture for compatibility

### Before Modifying Existing Telegram Code:
- Study: `api-reference.md` → affected methods
- Study: Current implementation → understand existing logic
- Study: `patterns.md` → ensure pattern consistency

## 📋 Learning Checklist Template

Claude should use this checklist before ANY telegram work:

```
🤖 Telegram Bot Learning Checklist

□ Documentation Study Completed:
  □ README.md (Core concepts)
  □ api-reference.md (API methods)
  □ patterns.md (Architecture patterns)
  □ examples/ (Code examples)

□ Current Implementation Analyzed:
  □ Models reviewed
  □ Controllers examined
  □ Configuration checked
  □ Database schema understood

□ Knowledge Validation:
  □ Can explain current implementation
  □ Can identify relevant patterns
  □ Can locate appropriate examples
  □ Understands integration points

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
- **Every 24 hours** for active telegram development
- **Every 7 days** for maintenance tasks
- **Before any major changes** regardless of timing

### Triggers for Immediate Refresh:
- Encountering unexpected errors
- Adding new telegram features
- Changing architecture patterns
- Performance optimization tasks

## 💡 Integration with Development Workflow

### When User Requests Telegram Work:
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
- Can explain telegram-bot architecture in project
- Can reference specific API methods for common tasks
- Can identify appropriate patterns for given scenarios
- Can locate and adapt relevant examples
- Can articulate current implementation state
- Can identify integration points and dependencies

This ensures Claude has comprehensive, current knowledge before making any changes to telegram functionality.