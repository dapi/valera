# Ruby LLM Pre-Work Checklist

## 🚨 MANDATORY PRE-WORK REQUIREMENT

**Claude MUST complete this checklist before ANY ruby_llm-related work:**

```
🤖 RUBY LLM PRE-WORK CHECKLIST

□ Documentation Study Completed:
  □ README.md studied (Core concepts + Rails integration)
  □ api-reference.md studied (Complete API + methods + responses)
  □ patterns.md studied (Architecture patterns + best practices)
  □ Examples reviewed (basic-chat.rb + tool-calls.rb + configuration.rb)

□ Current Implementation Analyzed:
  □ Chat model with acts_as_chat reviewed
  □ Message model with acts_as_message examined
  □ ToolCall model with acts_as_tool_call checked
  □ Configuration files (ruby_llm.rb, application_config.rb) reviewed
  □ Database schema for LLM tables understood

□ Knowledge Validation Passed:
  □ Can explain current ruby_llm implementation
  □ Can identify available providers and models
  □ Can locate appropriate API methods for task
  □ Understands acts_as macro usage in project
  □ Knows current tool/function calling setup
  □ Understands error handling strategy

□ Task Preparation Complete:
  □ Relevant patterns identified for task
  □ Similar examples located and adapted
  □ Integration points with Rails understood
  □ Dependencies and limitations identified

Study Time: ____ minutes
Last Study: ____
Ready to Proceed: ____ (must be "Yes")
```

## 🔄 AUTO-LEARNING TRIGGERS

Claude will automatically start learning protocol when:

### Query Keywords Detected:
- "ruby_llm", "llm", "ai", "chat", "message", "assistant"
- "tool", "function", "embedding", "generation", "model"
- "openai", "anthropic", "claude", "gpt", "gemini"
- "acts_as_chat", "acts_as_message", "acts_as_tool_call"

### File Mentions Detected:
- Files containing "ruby_llm", "llm", "chat", "message"
- `app/models/chat.rb`, `app/models/message.rb`, `app/models/tool_call.rb`
- `config/initializers/ruby_llm.rb`
- `config/configs/application_config.rb`

### Task Types:
- Adding LLM features
- Debugging LLM issues
- Modifying LLM configuration
- Implementing new chat functionality
- Adding tool/function calling
- Working with embeddings or image generation

## 📚 STUDY SEQUENCE (MANDATORY ORDER)

### 1. Core Documentation (5 min)
```
📖 docs/gems/ruby_llm/README.md
Focus: Basic setup, acts_as macros, Rails integration
Key takeaways: Configuration, providers, models, basic usage
```

### 2. API Reference (10 min)
```
📖 docs/gems/ruby_llm/api-reference.md
Focus: Complete API methods, response objects, error handling
Key takeaways: Chat methods, tool calls, embeddings, images
```

### 3. Architecture Patterns (10 min)
```
📖 docs/gems/ruby_llm/patterns.md
Focus: Design patterns, best practices, performance
Key takeaways: Service layer, caching, error handling, scaling
```

### 4. Code Examples (15 min)
```
💻 docs/gems/ruby_llm/examples/basic-chat.rb
Focus: Basic chat implementation, model selection

💻 docs/gems/ruby_llm/examples/tool-calls.rb
Focus: Function calling, tool definition and execution

💻 docs/gems/ruby_llm/examples/configuration.rb
Focus: Multi-provider setup, environment config
```

## 🧠 KNOWLEDGE VALIDATION QUESTIONS

Claude MUST be able to answer these before proceeding:

1. **Implementation State:**
   - What ruby_llm functionality currently exists?
   - Which models use acts_as macros?
   - How are providers and models configured?

2. **API Knowledge:**
   - Which API methods are needed for this task?
   - How are tool/function calls implemented?
   - What are the response object structures?

3. **Architecture:**
   - Which patterns apply to this LLM task?
   - How does this integrate with Rails models?
   - What are the testing requirements?

4. **Practical:**
   - Can you configure different providers?
   - Do you understand streaming responses?
   - Can you implement embeddings or image generation?

## ⚡ QUICK REFERENCE

### Common Tasks → Relevant Documentation:

| Task | Documentation Section |
|------|----------------------|
| **Add chat functionality** | patterns.md (Service Layer) + basic-chat.rb |
| **Implement tool calls** | tool-calls.rb + api-reference.md |
| **Configure new provider** | configuration.rb + README.md |
| **Add embeddings** | api-reference.md + patterns.md |
| **Debug LLM issues** | api-reference.md (Error handling) |
| **Performance optimization** | patterns.md (Caching + Performance) |
| **Model selection** | patterns.md (Model Selection Strategy) |

### API Methods → Documentation:
- **Chat methods** → api-reference.md (RubyLLM.chat)
- **Embeddings** → api-reference.md (RubyLLM.embed)
- **Image generation** → api-reference.md (RubyLLM.paint)
- **Tool calls** → api-reference.md (Tool Calls section)
- **Error handling** → api-reference.md (Error Types)

### acts_as Macros → Documentation:
- **acts_as_chat** → README.md (Active Record Integration)
- **acts_as_message** → README.md (Active Record Integration)
- **acts_as_tool_call** → README.md (Active Record Integration)

## 🚨 FAILURE CONDITIONS

Claude MUST NOT proceed with ruby_llm work if:

- ❌ Documentation study not completed
- ❌ Cannot answer validation questions
- ❌ Current implementation not understood
- ❌ acts_as usage not clear
- ❌ Provider configuration not understood
- ❌ Tool calling patterns not identified

## ✅ SUCCESS INDICATORS

Claude is ready when:

- ✅ All documentation sections studied
- ✅ Current implementation analyzed
- ✅ Validation questions answered correctly
- ✅ Task-specific preparation complete
- ✅ Can explain approach with examples
- ✅ Can identify potential issues
- ✅ Understands acts_as macro usage
- ✅ Can handle tool/function calling

## 🔄 REFRESH SCHEDULE

- **Active development:** Refresh every 1 hour
- **Debugging tasks:** Refresh every 6 hours
- **Maintenance:** Refresh every 24 hours
- **Major changes:** Always refresh regardless of timing

---

**This checklist ensures Claude has comprehensive, current knowledge before making any ruby_llm-related changes.**