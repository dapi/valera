SEMVER_BIN=./bin/semver
SEMVER=$(shell ${SEMVER_BIN})
STAGE ?= production
# Версия из последнего git tag без префикса 'v' (для Docker образов)
TAG ?= $(shell git describe --tags --abbrev=0 | sed 's/^v//')
# Registry from environment variable (required)
REGISTRY ?= $(REGISTRY)

# Default target
release: patch-release 

patch-release-and-deploy: patch-release watch deploy sleep infra-watch

minor:
	@${SEMVER_BIN} inc minor

patch:
	@${SEMVER_BIN} inc patch

bump-patch: patch push-semver
bump-minor: minor push-semver

push-semver:
	@echo "Increment version to ${SEMVER}"
	@git add .semver
	@git commit -m ${SEMVER}
	@git push

patch-release: bump-patch push-release
minor-release: bump-minor push-release

push-release:
	@gh release create ${SEMVER} --generate-notes
	@git pull --tags

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

watch:
	@${GH} run watch ${LATEST_RUN_ID}

infra-watch:
	@${INFRA_GH} run watch ${LATEST_INFRA_RUN_ID}

infra-view:
	@${INFRA_GH} run view ${LATEST_INFRA_RUN_ID} --log-failed

list:
	@${INFRA_GH} run list --workflow=${WORKFLOW} -L 3 -e workflow_dispatch

test-all-providers:
	PROVIDER=deepskeep ./bin/rails test

# Проверка существования git tag (ищем v$(TAG) так как теги с префиксом v)
guard-tag-exists:
	@git rev-parse "v$(TAG)" >/dev/null 2>&1 || \
		(echo "Error: Tag 'v$(TAG)' does not exist in git" && exit 1)

deploy: guard-tag-exists
	@test -n "$(INFRA_DIR)" || (echo "Error: INFRA_DIR is not set" && exit 1)
	@test -n "$(STAGE)" || (echo "Error: STAGE is not set" && exit 1)
	@echo "Deploying valera $(TAG) to $(STAGE)..."
	cd $(INFRA_DIR) && direnv exec . $(MAKE) app-deploy APP=valera STAGE=$(STAGE) TAG=$(TAG)
	@echo ""
	@echo "✓ Deploy completed!"
	@echo "  Image: $(REGISTRY)/valera:$(TAG)"
	@echo "  Stage: $(STAGE)"

docker-build: ## Build Docker image with version tags
	@echo "Building Docker image..."
	@VERSION=$$(${SEMVER_BIN}); \
	VERSION=$${VERSION#v}; \
	docker build \
		--build-arg VERSION=$$VERSION \
		--build-arg BUILD_DATE=$$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
		--build-arg GIT_SHA=$$(git rev-parse HEAD) \
		-t valera:dev -t valera:$$VERSION \
		-t $(REGISTRY)/valera:latest -t $(REGISTRY)/valera:$$VERSION .; \
	echo "✓ Docker image built: valera:dev, valera:$$VERSION, $(REGISTRY)/valera:latest, $(REGISTRY)/valera:$$VERSION"

docker-push: ## Push Docker image to registry
	@echo "Pushing Docker image to $(REGISTRY)..."
	@VERSION=$$(${SEMVER_BIN}); \
	VERSION=$${VERSION#v}; \
	docker push $(REGISTRY)/valera:latest && \
	docker push $(REGISTRY)/valera:$$VERSION; \
	echo "✓ Docker images pushed: $(REGISTRY)/valera:latest, $(REGISTRY)/valera:$$VERSION"

build-and-push: docker-build docker-push ## Build, push and deploy
	@echo "✓ Build and push completed!"
