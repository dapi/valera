# Claude AI Assistant Configuration

This directory contains configuration and learning protocols for Claude AI assistant when working with the Super Valera project.

## 📁 Configuration Files

### 🤖 Learning Protocols
- **`telegram-bot-learning.md`** - Complete learning protocol for telegram-bot functionality
- **`telegram-checklist.md`** - Mandatory pre-work checklist for telegram tasks
- **`pre-work-hook.rb`** - Automatic pre-work execution script

### 🔧 Context Processing
- **`context-processor.rb`** - Automatic context analysis and learning trigger system

## 🎯 Mandatory Learning Requirements

### For Telegram Bot Work:
Claude MUST complete the learning protocol before ANY telegram-related work:

1. **Auto-Detection**: Automatically detects telegram-related tasks
2. **Forced Learning**: Mandatory study before proceeding
3. **Structured Sequence**: Specific order of documentation study
4. **Knowledge Validation**: Must pass validation questions
5. **Current Analysis**: Understand existing implementation

### Trigger Conditions:
- Keywords: "telegram", "bot", "webhook", "chat", "message", "inline", "callback"
- Files: `app/models/chat*`, `app/models/message*`, `config/*telegram*`
- Tasks: Adding features, debugging, configuration changes

## 📚 Learning Sequence (Mandatory)

1. **Core Documentation** (5 min)
   - File: `docs/gems/telegram-bot/README.md`
   - Focus: Basic setup, API structure, core concepts

2. **API Reference** (10 min)
   - File: `docs/gems/telegram-bot/api-reference.md`
   - Focus: Complete API methods, parameters, error handling

3. **Architecture Patterns** (10 min)
   - File: `docs/gems/telegram-bot/patterns.md`
   - Focus: Design patterns, best practices, scalability

4. **Code Examples** (15 min)
   - Files: `docs/gems/telegram-bot/examples/*.rb`
   - Focus: Practical implementations, common patterns

5. **Current Implementation Analysis**
   - Analyze existing models, controllers, configuration
   - Understand current architecture and limitations

6. **Knowledge Validation**
   - Answer validation questions
   - Confirm understanding of key concepts

## 🚀 Usage Instructions

### For Claude AI Assistant:

#### When Starting Telegram-Related Work:
1. **Automatic Detection**: System will detect telegram-related context
2. **Learning Protocol**: Automatically start learning sequence
3. **Complete Checklist**: Use `telegram-checklist.md` for validation
4. **Proceed with Task**: Only after learning completion

#### Manual Learning Activation:
```bash
# Run pre-work hook manually
ruby .claude/pre-work-hook.rb "telegram bot command implementation"
```

#### Knowledge Refresh:
- **Active Development**: Every 1 hour
- **Debugging Tasks**: Every 6 hours
- **Maintenance**: Every 24 hours
- **Major Changes**: Always refresh

## ✅ Success Criteria

Claude is ready to work when:

- ✅ All documentation sections studied (40+ minutes total)
- ✅ Current implementation analyzed and understood
- ✅ Knowledge validation questions answered correctly
- ✅ Relevant patterns identified for task
- ✅ Examples located and adapted
- ✅ Integration points and dependencies understood
- ✅ Pre-work checklist completed

## 🔄 Workflow Integration

### Before Task Planning:
1. Detect telegram-related context
2. Execute learning protocol
3. Validate knowledge
4. Analyze current implementation
5. Plan with examples and patterns

### During Implementation:
1. Reference appropriate patterns
2. Adapt examples from documentation
3. Follow best practices from patterns
4. Maintain consistency with existing code

### After Implementation:
1. Update learning state timestamp
2. Document new patterns used
3. Note any new considerations
4. Prepare for next learning cycle

## 📊 Learning State Tracking

The system tracks:
- Last study timestamp for each gem
- Learning completion status
- Knowledge validation results
- Task-specific preparation notes

File: `~/.claude/learning_state.json`

## 🎓 Continuous Improvement

This system ensures:
- **Comprehensive Knowledge**: Full understanding before changes
- **Current Information**: Regular updates with latest patterns
- **Quality Implementation**: Use of best practices and examples
- **Consistent Architecture**: Alignment with established patterns
- **Efficient Development**: Reduced errors and rework

---

**This configuration system guarantees Claude has complete, current knowledge before making any telegram-related changes to the Super Valera project.**