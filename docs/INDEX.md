# Super Valera Project Documentation Index

## 🎯 Project Overview

**Super Valera** is an AI-powered Telegram bot for automotive service automation, built with Ruby on Rails 8.1 and integrated with advanced AI capabilities through the `ruby_llm` gem.

### 🏗️ Architecture Overview

- **Backend Framework**: Ruby on Rails 8.1
- **AI Integration**: ruby_llm gem with DeepSeek
- **Database**: PostgreSQL with Solid Queue/Cache/Cable
- **Bot Platform**: Telegram Bot API
- **Configuration**: anyway_config for centralized settings
- **Analytics**: Custom event tracking system

### 📚 Documentation Structure

#### **🚀 Quick Start**
- **[Main README](../README.md)** - Project overview and setup
- **[Development Guide](development/README.md)** - Developer setup and workflows
- **[Tech Stack](development/tech-stack.md)** - Complete technology overview

#### **🏗️ Architecture & Design**
- **[Architecture Decisions](architecture/decisions.md)** - System design rationale
- **[Domain Models](domain/models.md)** - Core domain entities
- **[Bounded Contexts](domain/bounded-contexts.md)** - Domain boundaries
- **[Error Handling Patterns](patterns/error-handling.md)** - Centralized error management

#### **📋 Requirements & Features**
- **[Requirements Overview](requirements/README.md)** - Feature documentation
- **[User Stories](requirements/user-stories/)** - Detailed user scenarios
- **[Technical Specifications](requirements/tsd/)** - Implementation specs
- **[API Documentation](requirements/api/api-telegram-webhook-v1.md)** - Webhook API

#### **🔧 Development & Testing**
- **[Development Setup](development/SETUP.md)** - Environment configuration
- **[Testing Guide](development/README.md#testing)** - Test patterns and standards
- **[YARD Documentation](development/YARD_DOCUMENTATION_STANDARDS.md)** - Code documentation
- **[Prompt Testing](development/prompt-testing-guide.md)** - AI prompt validation

#### **📊 Analytics & Monitoring**
- **[Analytics System](analytics/README.md)** - Event tracking implementation
- **[Metabase Setup](analytics/metabase-setup.md)** - Analytics dashboard
- **[Business Metrics](product/business-metrics.md)** - KPI definitions

#### **🛠️ Deployment**
- **[Deployment Overview](deployment/README.md)** - Production deployment
- **[Docker Configuration](deployment/DOCKER.md)** - Container setup
- **[Monitoring Setup](deployment/MONITORING.md)** - System monitoring

#### **💼 Business & Product**
- **[Product Constitution](product/constitution.md)** - Product requirements
- **[SaaS Overview](saas/saas-overview.md)** - Business model
- **[Competitor Analysis](saas/competitors.md)** - Market analysis
- **[Business Value](saas/business-value.md)** - Value proposition

#### **🔍 Gem Documentation**
- **[Gems Overview](gems/README.md)** - Key gem dependencies
- **[ruby_llm Integration](gems/ruby_llm/README.md)** - AI framework usage
- **[Telegram Bot Framework](gems/telegram-bot/README.md)** - Bot implementation
- **[VCR Testing](gems/vcr/README.md)** - HTTP testing patterns

#### **📝 Reference Materials**
- **[Glossary](domain/glossary.md)** - Domain terminology
- **[Terminology](domain/terminology.md)** - Standardized terms
- **[FLOW Documentation](FLOW.md)** - Development workflow
- **[Product Examples](product/data-examples/)** - Sample data

---

## 🔍 Navigation Guide

### For New Developers
1. Start with [README.md](../README.md) for project overview
2. Follow [Development Setup](development/SETUP.md) for environment configuration
3. Review [Architecture Decisions](architecture/decisions.md) for system understanding
4. Study [Error Handling Patterns](patterns/error-handling.md) for code standards

### For Product Managers
1. Review [Product Constitution](product/constitution.md) for requirements
2. Check [User Stories](requirements/user-stories/) for feature specifications
3. Monitor [Business Metrics](product/business-metrics.md) for KPI tracking
4. Understand [SaaS Model](saas/saas-overview.md) for business context

### For DevOps Engineers
1. Follow [Deployment Guide](deployment/README.md) for production setup
2. Configure [Monitoring](deployment/MONITORING.md) for system health
3. Set up [Analytics Dashboard](analytics/metabase-setup.md) for data visualization
4. Review [Docker Configuration](deployment/DOCKER.md) for container management

### For QA Engineers
1. Study [Testing Guide](development/README.md#testing) for test patterns
2. Use [Prompt Testing Guide](development/prompt-testing-guide.md) for AI validation
3. Reference [VCR Testing](gems/vcr/README.md) for HTTP testing
4. Check [User Stories](requirements/user-stories/) for acceptance criteria

---

## 🏷️ Document Status Indicators

| Status | Meaning |
|--------|---------|
| ✅ **Current** | Up-to-date and production-ready |
| 🔄 **In Progress** | Being actively developed |
| ⚠️ **Needs Review** | Requires updates or validation |
| 📋 **Planned** | Scheduled for creation |

---

## 🔗 Cross-References

### Component Relationships
```
Telegram Webhook → Chat Model → ruby_llm → AI Response
     ↓                ↓              ↓
Analytics Tracking → Message Store → Tool Calls → Booking Creation
```

### Data Flow
```
User Message → Webhook Controller → LLM Processing → Tool Execution → Response Generation
     ↓               ↓                    ↓              ↓              ↓
Analytics Event → Message Storage → Tool Call Record → Booking Record → Telegram Response
```

### Service Dependencies
```
Chat System → ruby_llm → DeepSeek API
Booking System → Active Record → PostgreSQL
Analytics → Event Tracking → Metabase Dashboard
```

---

## 📊 Project Metrics

### Code Organization
- **Models**: 7 core ActiveRecord models
- **Controllers**: 2 main controllers (webhook, application)
- **Services**: 9 business logic services
- **Jobs**: 3 background job processors
- **Tools**: 2 AI tool implementations

### Testing Coverage
- **Unit Tests**: Model and service testing
- **Integration Tests**: Full workflow testing
- **VCR Tests**: External API mocking
- **Performance Tests**: Analytics system validation

### Documentation Quality
- **API Docs**: Complete webhook documentation
- **Architecture**: Design rationale documented
- **Development**: Comprehensive setup guides
- **Business**: Product requirements clearly defined

---

*Last Updated: 2025-10-27*
*Documentation Version: 3.0*
*Maintained by: Danil Pismenny*