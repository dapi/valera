# Shell settings for proper signal handling (Ctrl+C)
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

# Load environment variables from infra repo (if available)
INFRA_DIR ?= $(HOME)/code/brandymint/infra
-include $(INFRA_DIR)/.env
-include $(INFRA_DIR)/.env.secrets

# Export variables for sub-make (infra commands)
export PRODUCTION_VALERA_DATABASE_HOST
export PRODUCTION_VALERA_DATABASE_PASSWORD
export PRODUCTION_VALERA_DATABASE_USERNAME
export PRODUCTION_VALERA_DATABASE_NAME

SEMVER_BIN=./bin/semver
SEMVER=$(shell ${SEMVER_BIN})
STAGE ?= production
# Version from latest git tag without 'v' prefix (for Docker images)
TAG ?= $(shell git describe --tags --abbrev=0 | sed 's/^v//')
# Registry from environment variable (required)
REGISTRY ?= $(REGISTRY)
GH=gh
SLEEP=5

# Git branch detection for Docker tagging
BRANCH_NAME := $(shell git rev-parse --abbrev-ref HEAD)
# Sanitize branch name for Docker tags: replace invalid chars with -, limit to 128 chars
SANITIZED_BRANCH := $(shell echo "$(BRANCH_NAME)" | sed 's/[^a-zA-Z0-9._-]/-/g' | cut -c1-128)
IS_MAIN_BRANCH := $(shell [ "$(BRANCH_NAME)" = "main" -o "$(BRANCH_NAME)" = "master" ] && echo true || echo false)
GIT_SHORT_SHA := $(shell git rev-parse --short HEAD)

# Default target
release: patch-release

major:
	@${SEMVER_BIN} inc major

minor:
	@${SEMVER_BIN} inc minor

patch:
	@${SEMVER_BIN} inc patch

bump-major: major push-semver
bump-patch: patch push-semver
bump-minor: minor push-semver

push-semver:
	@echo "Increment version to ${SEMVER}"
	@git add .semver
	@git commit -m ${SEMVER}
	@git push

# Release with automatic changelog generation, build, and deploy
patch-release: patch update-changelog commit-release push-release build-and-push deploy deploy-wait deploy-status
minor-release: minor update-changelog commit-release push-release build-and-push deploy deploy-wait deploy-status
major-release: major update-changelog commit-release push-release build-and-push deploy deploy-wait deploy-status

commit-release: ## Commit version bump and changelog together
	@echo "Committing release ${SEMVER}..."
	@git add .semver CHANGELOG.md
	@git commit -m "Release ${SEMVER}"
	@git push

push-release:
	@if [ "$(IS_MAIN_BRANCH)" = "true" ]; then \
		gh release create ${SEMVER} --generate-notes --target $(BRANCH_NAME); \
	else \
		echo "Creating pre-release for feature branch $(BRANCH_NAME)..."; \
		gh release create ${SEMVER}-$(SANITIZED_BRANCH) --generate-notes --target $(BRANCH_NAME) --prerelease; \
	fi
	@git fetch --tags

update-changelog: ## Generate changelog section using Claude/Codex CLI
	@./scripts/update_changelog.sh

sleep:
	@echo "Wait ${SLEEP} seconds for workflow to run"
	@sleep ${SLEEP}

deploy-wait:
	@echo "Wait for deploy status"
	@sleep 2

deploy-status: ## Monitor deployment status with auto-refresh until consistent
	@echo "Monitoring deployment status..."
	@./scripts/deploy_status_monitor.sh "$(INFRA_DIR)" "$(STAGE)"

# Verify git tag exists (with automatic fetch, branch-aware)
guard-tag-exists:
	@git fetch --tags --quiet
	@VERSION=$$(${SEMVER_BIN}); \
	VERSION=$${VERSION#v}; \
	if [ "$(IS_MAIN_BRANCH)" = "true" ]; then \
		TAG_TO_CHECK="v$$VERSION"; \
	else \
		TAG_TO_CHECK="v$$VERSION-$(SANITIZED_BRANCH)"; \
	fi; \
	echo "Checking for tag: $$TAG_TO_CHECK"; \
	git rev-parse "$$TAG_TO_CHECK" >/dev/null 2>&1 || \
		(echo "Error: Tag '$$TAG_TO_CHECK' does not exist in git" && exit 1)

deploy: guard-tag-exists ## Deploy via infra repo (branch-aware)
	@test -n "$(INFRA_DIR)" || (echo "Error: INFRA_DIR is not set" && exit 1)
	@trap 'echo ""; echo "Deploy interrupted"; exit 130' INT TERM; \
	VERSION=$$(${SEMVER_BIN}); \
	VERSION=$${VERSION#v}; \
	if [ "$(IS_MAIN_BRANCH)" = "true" ]; then \
		DEPLOY_TAG=$$VERSION; \
		echo "Deploying valera $$VERSION (release) to $(STAGE)..."; \
	else \
		DEPLOY_TAG=$$VERSION-$(SANITIZED_BRANCH); \
		echo "Deploying valera $$VERSION-$(SANITIZED_BRANCH) (feature branch $(BRANCH_NAME)) to $(STAGE)..."; \
	fi; \
	cd $(INFRA_DIR) && direnv exec . $(MAKE) app-deploy APP=valera STAGE=$(STAGE) TAG=$$DEPLOY_TAG; \
	echo ""; \
	echo "Deploy completed!"; \
	echo "  Image: $(REGISTRY)/valera:$$DEPLOY_TAG"; \
	echo "  Stage: $(STAGE)"

docker-build: ## Build Docker image with version tags (branch-aware)
	@echo "Building Docker image..."; \
	echo "  Branch: $(BRANCH_NAME) (sanitized: $(SANITIZED_BRANCH))"; \
	echo "  Is main/master: $(IS_MAIN_BRANCH)"; \
	trap 'echo ""; echo "Build interrupted"; exit 130' INT TERM; \
	START=$$(date +%s); \
	VERSION=$$(${SEMVER_BIN}); \
	VERSION=$${VERSION#v}; \
	if [ "$(IS_MAIN_BRANCH)" = "true" ]; then \
		TAGS="-t valera:dev -t valera:$$VERSION -t $(REGISTRY)/valera:latest -t $(REGISTRY)/valera:$$VERSION"; \
		echo "  Tags (release): valera:dev, valera:$$VERSION, $(REGISTRY)/valera:latest, $(REGISTRY)/valera:$$VERSION"; \
	else \
		TAGS="-t valera:$$VERSION-$(SANITIZED_BRANCH) -t $(REGISTRY)/valera:$$VERSION-$(SANITIZED_BRANCH)"; \
		echo "  Tags (feature): valera:$$VERSION-$(SANITIZED_BRANCH), $(REGISTRY)/valera:$$VERSION-$(SANITIZED_BRANCH)"; \
	fi; \
	docker build \
		--build-arg VERSION=$$VERSION \
		--build-arg BUILD_DATE=$$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
		--build-arg GIT_SHA=$(GIT_SHORT_SHA) \
		$$TAGS .; \
	END=$$(date +%s); \
	echo "Docker image built successfully"; \
	echo "Build time: $$((END - START)) seconds"

docker-push: ## Push Docker image to registry (branch-aware)
	@trap 'echo ""; echo "Push interrupted"; exit 130' INT TERM; \
	echo "Pushing Docker image to $(REGISTRY)..."; \
	VERSION=$$(${SEMVER_BIN}); \
	VERSION=$${VERSION#v}; \
	if [ "$(IS_MAIN_BRANCH)" = "true" ]; then \
		docker push $(REGISTRY)/valera:latest && \
		docker push $(REGISTRY)/valera:$$VERSION; \
		echo "Docker images pushed: $(REGISTRY)/valera:latest, $(REGISTRY)/valera:$$VERSION"; \
	else \
		docker push $(REGISTRY)/valera:$$VERSION-$(SANITIZED_BRANCH); \
		echo "Docker image pushed: $(REGISTRY)/valera:$$VERSION-$(SANITIZED_BRANCH)"; \
	fi

build-and-push: docker-build docker-push ## Build and push Docker image
	@echo "Build and push completed!"

.PHONY: test
test:
	./bin/rails db:test:prepare test:system
	./bin/rake test
	SYSTEM_PROMPT_PATH=data/system-prompt-v2.md ./bin/rake test

up:
	./bin/dev

clean:
	rm -fr tmp/postgres_data/
	dropuser -h localhost -U postgres

create_user:
	createuser -h localhost -U postgres -s

deps:
	brew install terminal-notifier
	brew install oven-sh/bun/bun
	npm install
	npx playwright install chromium
	bundle install

test-all-providers:
	PROVIDER=deepskeep ./bin/rails test

production-psql:
	PGOPTIONS='' PGPASSWORD=${PRODUCTION_VALERA_DATABASE_PASSWORD} psql -h ${PRODUCTION_VALERA_DATABASE_HOST} -p 5433 -U ${PRODUCTION_VALERA_DATABASE_USERNAME} -d ${PRODUCTION_VALERA_DATABASE_NAME}

# Clone production database to local Docker postgres
# Usage: make clone-production-db
# Prerequisites: dip up (postgres running), production env vars set
clone-production-db: guard-production-env
	@echo "Dumping production database..."
	@PGOPTIONS='' PGPASSWORD=${PRODUCTION_VALERA_DATABASE_PASSWORD} \
		pg_dump -h ${PRODUCTION_VALERA_DATABASE_HOST} -p 5433 \
		-U ${PRODUCTION_VALERA_DATABASE_USERNAME} \
		-d ${PRODUCTION_VALERA_DATABASE_NAME} \
		--no-owner --no-acl --clean --if-exists \
		-Fc -f tmp/production_dump.dump
	@echo "Dump saved to tmp/production_dump.dump"
	@echo ""
	@echo "Recreating local database..."
	@docker compose exec -T postgres psql -U valera -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'valera_development' AND pid <> pg_backend_pid();" > /dev/null 2>&1 || true
	@docker compose exec -T postgres dropdb -U valera --if-exists valera_development
	@docker compose exec -T postgres createdb -U valera valera_development
	@echo "Local database recreated"
	@echo ""
	@echo "Restoring dump to local database..."
	@cat tmp/production_dump.dump | docker compose exec -T postgres pg_restore -U valera -d valera_development --no-owner --no-acl || true
	@echo "Database restored"
	@echo ""
	@echo "Running migrations..."
	@dip rails db:migrate
	@echo ""
	@echo "Sync complete! Production data is now in local Docker postgres."

guard-production-env:
	@test -n "${PRODUCTION_VALERA_DATABASE_HOST}" || (echo "Error: PRODUCTION_VALERA_DATABASE_HOST is not set" && exit 1)
	@test -n "${PRODUCTION_VALERA_DATABASE_PASSWORD}" || (echo "Error: PRODUCTION_VALERA_DATABASE_PASSWORD is not set" && exit 1)
	@test -n "${PRODUCTION_VALERA_DATABASE_USERNAME}" || (echo "Error: PRODUCTION_VALERA_DATABASE_USERNAME is not set" && exit 1)
	@test -n "${PRODUCTION_VALERA_DATABASE_NAME}" || (echo "Error: PRODUCTION_VALERA_DATABASE_NAME is not set" && exit 1)

production-logs:
	kubectl logs -n production deployment/valera --tail=200

production-rails-runner:
	@bin/production-rails-runner $(ARGS)
