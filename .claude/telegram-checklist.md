# Telegram Bot Pre-Work Checklist

## 🚨 MANDATORY PRE-WORK REQUIREMENT

**Claude MUST complete this checklist before ANY telegram-related work:**

```
🤖 TELEGRAM BOT PRE-WORK CHECKLIST

□ Documentation Study Completed:
  □ README.md studied (Core concepts + API structure)
  □ api-reference.md studied (Complete API methods + error handling)
  □ patterns.md studied (Architecture patterns + best practices)
  □ Examples reviewed (advanced-handlers.rb)

□ Current Implementation Analyzed:
  □ Existing telegram models reviewed
  □ Controllers and endpoints examined
  □ Configuration files checked
  □ Database schema understood
  □ Current authentication method identified

□ Knowledge Validation Passed:
  □ Can explain current telegram implementation
  □ Can identify relevant API methods for task
  □ Can locate appropriate code patterns
  □ Understands webhook vs long polling setup
  □ Knows current error handling strategy

□ Task Preparation Complete:
  □ Relevant patterns identified for task
  □ Similar examples located
  □ Integration points understood
  □ Dependencies identified

Study Time: ____ minutes
Last Study: ____
Ready to Proceed: ____ (must be "Yes")
```

## 🔄 AUTO-LEARNING TRIGGERS

Claude will automatically start learning protocol when:

### Query Keywords Detected:
- "telegram", "bot", "webhook", "chat", "message"
- "inline", "callback", "keyboard", "button"
- "tg_", "telegr", "bot_token"

### File Mentions Detected:
- Files containing "telegram", "bot", "webhook", "chat"
- `app/models/chat*`, `app/models/message*`
- `config/initializers/*telegram*`
- `app/controllers/*telegram*`

### Task Types:
- Adding telegram features
- Debugging telegram issues
- Modifying telegram configuration
- Implementing new bot commands
- Setting up webhooks

## 📚 STUDY SEQUENCE (MANDATORY ORDER)

### 1. Core Documentation (5 min)
```
📖 docs/gems/telegram-bot/README.md
Focus: Basic setup, message types, core concepts
Key takeaways: API structure, authentication, patterns
```

### 2. API Reference (10 min)
```
📖 docs/gems/telegram-bot/api-reference.md
Focus: Complete API methods, parameters, error codes
Key takeaways: Method signatures, limits, error handling
```

### 3. Architecture Patterns (10 min)
```
📖 docs/gems/telegram-bot/patterns.md
Focus: Design patterns, best practices, scalability
Key takeaways: State management, error handling, testing
```

### 4. Code Examples (15 min)
```
💻 docs/gems/telegram-bot/examples/advanced-handlers.rb
Focus: Complex scenarios, file handling, state
```

## 🧠 KNOWLEDGE VALIDATION QUESTIONS

Claude MUST be able to answer these before proceeding:

1. **Implementation State:**
   - What telegram functionality currently exists?
   - Which models handle telegram data?
   - How is authentication currently configured?

2. **API Knowledge:**
   - Which API methods are needed for this task?
   - What are the parameter requirements?
   - How are errors handled?

3. **Architecture:**
   - Which patterns apply to this task?
   - How does this integrate with existing code?
   - What are the testing requirements?

4. **Practical:**
   - Can you locate relevant examples?
   - Do you understand the webhook setup?
   - Can you identify potential issues?

## ⚡ QUICK REFERENCE

### Common Tasks → Relevant Documentation:

| Task | Documentation Section |
|------|----------------------|
| **Add new command** | patterns.md (Command Handler) + advanced-handlers.rb |
| **Handle files** | advanced-handlers.rb + api-reference.md |
| **Add keyboard** | patterns.md + advanced-handlers.rb |
| **Debug issues** | api-reference.md (Error handling) |
| **Implement state** | patterns.md (State Machine) + advanced-handlers.rb |
| **Complex scenarios** | advanced-handlers.rb + patterns.md |

### Error Codes → Documentation:
- **403 Forbidden** → api-reference.md (Authentication errors)
- **429 Too Many Requests** → patterns.md (Rate limiting)
- **400 Bad Request** → api-reference.md (Validation errors)
- **401 Unauthorized** → README.md (Token setup)

## 🚨 FAILURE CONDITIONS

Claude MUST NOT proceed with telegram work if:

- ❌ Documentation study not completed
- ❌ Cannot answer validation questions
- ❌ Current implementation not understood
- ❌ Relevant patterns not identified
- ❌ Examples not located/adapted

## ✅ SUCCESS INDICATORS

Claude is ready when:

- ✅ All documentation sections studied
- ✅ Current implementation analyzed
- ✅ Validation questions answered correctly
- ✅ Task-specific preparation complete
- ✅ Can explain approach with examples
- ✅ Can identify potential issues

## 🔄 REFRESH SCHEDULE

- **Active development:** Refresh every 1 hour
- **Debugging tasks:** Refresh every 6 hours
- **Maintenance:** Refresh every 24 hours
- **Major changes:** Always refresh regardless of timing

---

**This checklist ensures Claude has comprehensive, current knowledge before making any telegram-related changes.**