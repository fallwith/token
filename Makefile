SHELL            := /usr/bin/env bash
ROOT             := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
STYLUAC          := $(ROOT)/.stylua.toml
SELENEC          := $(ROOT)/selene.toml

.PHONY: all format lint install-hooks help

all: format lint

# Install git hooks
install-hooks:
	@git config core.hooksPath .githooks

# Format all Lua files according to .stylua.toml
format:
	@stylua --config-path "$(STYLUAC)" "$(ROOT)"

# Lint all Lua files
lint:
	@selene --config "$(SELENEC)" "$(ROOT)"

# Display available targets
help:
	@echo "Available targets:"
	@echo "  all           - Format and lint"
	@echo "  format        - Format Lua files with stylua"
	@echo "  lint          - Lint Lua files with selene"
	@echo "  install-hooks - Enable git pre-commit hook"
