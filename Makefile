# Standard targets for every project under AI/ (see ../AGENTS.md).

.DEFAULT_GOAL := help

IMAGE ?= g0no:latest

.PHONY: help deps build test lint audit check run clean import docker-build docker-up docker-down docker-logs docker-import

help: ## list the targets
	@grep -E '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  %-14s %s\n", $$1, $$2}'

deps: ## install gems into vendor/bundle (if missing)
	@bundle config set --local path vendor/bundle
	@bundle check >/dev/null || bundle install

build: deps ## install gems and create or migrate the development database
	bin/rails db:prepare

test: deps ## run all tests
	bin/rails test

lint: deps ## style check (rubocop) and security static analysis (brakeman)
	bin/rubocop
	bin/brakeman --no-pager --quiet

audit: deps ## check gems for known vulnerabilities (downloads the advisory database)
	bin/bundler-audit check --update

check: lint test ## lint and test; must pass before a commit

run: build ## build and start the development server on http://localhost:3000
	bin/rails server

clean: ## remove caches, logs, compiled assets and test uploads (keeps databases in storage/)
	rm -rf tmp/cache tmp/storage/* public/assets
	rm -f log/*.log

import: deps ## import notes from the legacy CouchDB (needs COUCHDB_URL)
	@test -n "$(COUCHDB_URL)" || { echo "COUCHDB_URL is not set, e.g. COUCHDB_URL=http://127.0.0.1:5984/gono-production"; exit 1; }
	bin/rails couchdb:import

docker-build: ## build the production Docker image
	docker build -t $(IMAGE) .

docker-up: ## build and start the app with docker compose on http://localhost:3000 (needs .env)
	@test -f .env || { echo ".env is missing: cp .env.example .env and set SECRET_KEY_BASE (bin/rails secret)"; exit 1; }
	docker compose up -d --build

docker-down: ## stop the docker compose app (data stays in the storage volume)
	docker compose down

docker-logs: ## follow the docker compose app logs
	docker compose logs -f web

docker-import: ## import from the legacy CouchDB inside the container (COUCHDB_URL in .env)
	@test -f .env || { echo ".env is missing: cp .env.example .env"; exit 1; }
	docker compose run --rm web sh -c "bin/rails db:prepare && bin/rails couchdb:import"
