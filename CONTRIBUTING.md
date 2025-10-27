# 🤝 Contributing to Valera

Thank you for your interest in contributing to Valera! This guide will help you get started.

## 🚀 Quick Start

### For Developers
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Follow [FLOW.md](docs/FLOW.md) for development process
4. Make your changes
5. Test your changes thoroughly
6. Submit a pull request

### For Documentation
1. Improve existing documentation
2. Add examples and clarifications
3. Fix typos and formatting
4. Submit a pull request

## 🏗️ Development Workflow

### FLOW Process
All development MUST follow the [FLOW.md](docs/FLOW.md) two-document approach:
- **User Story** - What and why
- **Technical Specification Document** - How

### Code Standards
- Follow existing code style and patterns
- Use Ruby on Rails conventions
- Write meaningful commit messages
- Include tests for new features

### Key Rules
- **Models:** Always use `rails generate model` for creating models
- **Error Handling:** Use `ErrorLogger` instead of `Bugsnag.notify()`
- **Configuration:** Use `anyway_config`, NO `.env*` files
- **Testing:** Don't use File.write/File.delete in tests, don't modify ENV

## 📚 Documentation

### Documentation First
This project uses AI-first documentation approach:
- Documentation is created primarily for AI agents
- Clear requirements and context are essential
- Follow the [Product Constitution](docs/product/constitution.md)

### Structure
- **WHY documents** → `architecture/decisions.md`, `product/`
- **HOW documents** → `CLAUDE.md`, `FLOW.md`, technical docs
- **WHAT documents** → `requirements/`, `domain/`

## 🧪 Testing

### Running Tests
```bash
# Run all tests
rails test

# Run specific test file
rails test test/models/user_test.rb

# Run with coverage
rails test:coverage
```

### Testing Rules
- Write tests for new features
- Test edge cases and error conditions
- Don't modify the filesystem directly in tests
- Don't change ENV variables in tests

## 📝 Submitting Changes

### Pull Request Process
1. Update documentation as needed
2. Ensure all tests pass
3. Follow the pull request template
4. Request review from maintainers
5. Respond to feedback promptly

### Commit Message Format
```
type(scope): brief description

Detailed explanation if needed
```

Types:
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `style:` Code style
- `refactor:` Refactoring
- `test:` Tests
- `chore:` Maintenance

## 🏷️ Labels and Priority

### Priority Labels
- `critical` - Blocking issues, security
- `high` - Important features, bugs
- `medium` - Enhancements, improvements
- `low` - Nice to have, optimizations

### Type Labels
- `bug` - Bug reports
- `feature` - New features
- `documentation` - Docs improvements
- `testing` - Test related
- `performance` - Performance issues

## 🤖 AI Agent Guidelines

### For Claude Code and AI Agents
- Read [CLAUDE.md](CLAUDE.md) first for technical guidance
- Follow [FLOW.md](docs/FLOW.md) for development process
- Use [docs/README.md](docs/README.md) for navigation
- Check [domain/glossary.md](docs/domain/glossary.md) for terminology

### Key Resources
- **Technical Stack:** [CLAUDE.md](CLAUDE.md)
- **Architecture:** [architecture/decisions.md](architecture/decisions.md)
- **Product Requirements:** [product/constitution.md](docs/product/constitution.md)
- **Domain Knowledge:** [domain/glossary.md](docs/domain/glossary.md)

## 🚨 Getting Help

### Resources
- [Documentation](docs/README.md)
- [Development Guide](docs/development/README.md)
- [Technical Standards](CLAUDE.md)
- [Architecture Decisions](docs/architecture/decisions.md)

### Questions?
- Create an issue for questions
- Start discussions in pull requests
- Refer to existing documentation first

## 📄 License

By contributing, you agree that your contributions will be licensed under the same license as the project.

---

Thank you for contributing to Valera! 🎉