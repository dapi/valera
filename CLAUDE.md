# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Valera is an AI-powered chatbot for car service automation built with Ruby on Rails 8.1. The application uses the `ruby_llm` gem to provide conversational AI capabilities and is designed to interface with Telegram for customer interactions around car services.

## Core Technologies

- **Ruby on Rails 8.1** - Main application framework
- **PostgreSQL** - Primary database
- **ruby_llm gem (~> 1.8)** - AI/LLM integration
- **anyway_config (~> 2.7)** - Configuration management
- **Tailwind CSS** - Styling framework
- **Hotwire (Turbo + Stimulus)** - Frontend framework
- **Solid Suite** (Cache, Queue, Cable) - Background processing and caching
- **Slim** - Template engine
- **Minitest** - Testing framework

## Development Commands

### Essential Rails Commands
```bash
# Start development server
bin/dev

# Run Rails console
bin/rails console

# Run database migrations
bin/rails db:migrate

# Create new migration
bin/rails generate migration <migration_name>

# Run tests
bin/rails test
# OR
rake test
# OR
make test
```

### Code Quality and Security
```bash
# Run RuboCop for code style checking
bin/rubocop

# Run RuboCop with auto-correction
bin/rubocop -a

# Run security audit
bin/bundler-audit

# Run Brakeman security scanner
bin/brakeman

# Run all quality checks (CI script)
bin/ci
```

### Background Jobs and Services
```bash
# Start Solid Queue worker
bin/jobs

# Start Solid Cable server
bin/cable

# Check cache status
bin/rails cache:status
```

## Application Architecture

### Core Models
- **Chat** - Main conversation entity using `acts_as_chat` from ruby_llm
- **Message** - Individual messages with attachment support via `has_many_attached :attachments`
- **ToolCall** - LLM tool/function call tracking using `acts_as_tool_call`
- **Model** - AI model configuration and management

### Configuration Management
The application uses `anyway_config` for sophisticated configuration handling:

- Main configuration class: `ApplicationConfig` (config/configs/application_config.rb)
- Environment-based configuration with type coercion
- Required parameter validation
- Singleton pattern for global access via class methods

Key configuration sections:
- LLM provider and model settings
- File paths for prompts and data
- Telegram bot integration
- Rate limiting configuration
- Conversation management settings

### Security and Testing Practices
- **No File.write/File.delete** in tests - use safe testing patterns
- **No ENV modifications** in test environment
- **Logging in tests is not mocked or verified**
- Specifications are stored in `./specs/` directory
- Implementation plans are stored in `./protocols/` directory (strict rule)

### Development Workflow
- Russian language interface support (car service domain context)
- All implementation plans must be saved to `.protocols/` directory
- Specifications are saved to `./specs/` directory
- Use MCP context7 for studying Ruby gems
- Refer to `./docs/gems/rubyllm.com` for ruby_llm gem usage examples

## Database Schema

The application uses PostgreSQL with Rails 8.1's default schema management. Key schema files:
- `db/schema.rb` - Main database schema
- `db/cache_schema.rb` - Solid Cache schema
- `db/queue_schema.rb` - Solid Queue schema
- `db/cable_schema.rb` - Solid Cable schema

## Asset Management

- **Propshaft** - Modern Rails asset pipeline
- **Importmap** - JavaScript module management without build step
- **Tailwind CSS** - Utility-first CSS framework
- **Slim templates** - Lightweight template engine

## Deployment and Operations

- Docker-based deployment with multi-stage builds
- Puma web server with Thruster for HTTP acceleration
- Health check endpoint at `/up`
- Environment-based configuration loading

## Important Development Notes

- Do not read or use `.env*` files (per user instructions)
- Study `anyway_config` gem documentation before modifying ApplicationConfig
- The application is designed for Russian-speaking users in car service domain
- All conversation history and AI interactions are persisted through the Chat/Message models
- Tool calls are tracked separately for audit and debugging purposes- Прочитай README.md

## Testing

Tests are located in `test/` directory and use Minitest framework. Run with `rake test` or `make test`.

## Important Notes

- Прежде чем менять ApplicationCOnfig или планировать его изменить изучи gem anyway_config
- Do not read or use `.env*` files (per user instructions)
- Use MCP context7 for studying Ruby gems
- Service prices and implementation plans are referenced in CLAUDE.md for quick access
- ВСЕГДА сохраняйте планы имплементации в `.protocols/` - это строгое правило
- Спецификации сохраняйте в `./specs/`
- The bot supports Russian language interface (car service context)
- НЕ используются File.write и File.delete и прочие небезопасные методы в тестах
- НЕ изменеются ENV-ы в тестах
- Не удаляем спецификации даже если по ним уже выполнены планы имплементации
  (сами планы можно удалять)
- Логирование в тестах не мокается и НЕ проверяется
- По тому как использовать gem ruby_llm заглядывай в ./docs/gems/rubyllm.com
