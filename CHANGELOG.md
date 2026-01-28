# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.41.0] - 2026-01-28

### Changed
- Update Makefile

## [0.40.0] - 2026-01-28

### Added
- Add Models resource for superusers with filters (#137) (#179)
- Показывать информативную страницу для несуществующего tenant-а (#176)

### Changed
- Switch ruby_llm from GitHub source to released gem v1.11.0
- Add release pipeline with changelog generation and deploy monitoring
- Bump ruby_llm from `1e315ab` to `1ad64c8` (#194)
- Bump dip from 8.1.0 to 8.2.5 (#184)
- Bump pg from 1.6.2 to 1.6.3 (#185)
- Bump rubocop-rails from 2.34.2 to 2.34.3 (#186)
- Bump turbo-rails from 2.0.20 to 2.0.21 (#192)
- Bump importmap-rails from 2.2.2 to 2.2.3 (#190)
- Bump bcrypt from 3.1.20 to 3.1.21 (#188)
- Bump selenium-webdriver from 4.39.0 to 4.40.0
- Update trix
- Address code review findings
- Bump minitest from 5.27.0 to 6.0.1
- Update CLAUDE.md
- Improve defaults
- Improve .envrc
- Improve funnel_data: add tenant isolation test and clarifying comment (#177)
- Update init.sh
- Update .envrc

### Fixed
- Remove autofocus from landing page phone fields
- Add manager to valid roles, remove data cleanup migration
- Remove unrelated schema changes from local dev DB
- Validate message roles to prevent RubyLLM::InvalidRoleError (#195)
- Add array coercion for web_console_permissions and allowed_hosts
- Исправлен лимит сообщений в чатах dashboard
- Pass ENV vars to Docker and add server stop instruction
- Docker env vars и инструкции для AI-агентов
- correct tailwind-watch input/output paths
