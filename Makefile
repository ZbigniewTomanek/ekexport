# Makefile for ekexport (SwiftPM CLI)

BINARY := ekexport
SWIFT := swift
PREFIX ?= /usr/local
ARGS ?=

BUILD_DIR := .build
DEBUG_BIN := $(BUILD_DIR)/debug/$(BINARY)
RELEASE_BIN := $(BUILD_DIR)/release/$(BINARY)

.DEFAULT_GOAL := help

.PHONY: help build run release release-run test clean install uninstall

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make <target>\n\nTargets:\n"} /^[a-zA-Z0-9_-]+:.*##/ { printf "  %-15s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

build: ## Build debug binary
	$(SWIFT) build

run: ## Run in debug: make run ARGS="..."
	$(SWIFT) run $(BINARY) -- $(ARGS)

release: ## Build optimized release binary
	$(SWIFT) build -c release

release-run: release ## Run release binary: make release-run ARGS="..."
	$(RELEASE_BIN) $(ARGS)

test: ## Run tests
	$(SWIFT) test

clean: ## Clean build artifacts
	$(SWIFT) package clean

install: release ## Install release binary to $(PREFIX)/bin
	install -d $(PREFIX)/bin
	install -m 0755 $(RELEASE_BIN) $(PREFIX)/bin/$(BINARY)

uninstall: ## Remove installed binary from $(PREFIX)/bin
	-rm -f $(PREFIX)/bin/$(BINARY)

