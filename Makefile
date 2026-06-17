# ============================================================================
# xrepl — top-level build system
#
# This repo is polyglot: an LFE/OTP application (rebar3) and a Rust terminal
# client (cargo workspace), side by side. This Makefile owns the shared
# variables and the *aggregate* targets, and includes two language modules:
#
#   mk/lfe.mk   — the LFE / BEAM side  (targets suffixed -lfe), help-lfe
#   mk/rust.mk  — the Rust workspace   (targets suffixed -rust), help-rust
#
# The included modules expect the shared variables defined below (colors,
# identity, git); run everything through this Makefile, not the modules
# directly.
#
#   make            # help (general + lfe + rust)
#   make build      # compile both sides
#   make test       # test both sides
#   make check      # lint + test, both sides
# ============================================================================

# --- ANSI colors (shared) ---------------------------------------------------
BLUE   := \033[1;34m
GREEN  := \033[1;32m
YELLOW := \033[1;33m
RED    := \033[1;31m
CYAN   := \033[1;36m
RESET  := \033[0m

# --- Identity (shared by the included modules) ------------------------------
PROJECT_NAME := xrepl
CODE_NAME    := xrepl
APP_VERSION  := $(shell grep vsn src/$(PROJECT_NAME).app.src 2>/dev/null | cut -d'"' -f2)
GIT_COMMIT   := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
GIT_BRANCH   := $(shell git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
BUILD_TIME   := $(shell date -u '+%Y-%m-%dT%H:%M:%SZ')
RUST_VERSION := $(shell rustc --version 2>/dev/null || echo "not installed")
OTP_VERSION  := $(shell erl -noshell -eval 'io:format("~s",[erlang:system_info(otp_release)]),halt().' 2>/dev/null || echo "not installed")
REBAR        := rebar3

.DEFAULT_GOAL := help

# --- Language modules -------------------------------------------------------
include mk/lfe.mk
include mk/rust.mk

# ============================================================================
# Help (general + per-language sections)
# ============================================================================
.PHONY: help
help: help-general help-lfe help-rust

.PHONY: help-general
help-general:
	@echo ""
	@echo "$(CYAN)╔══════════════════════════════════════════════════════════╗$(RESET)"
	@echo "$(CYAN)║$(RESET) $(BLUE)$(PROJECT_NAME) v$(APP_VERSION) — polyglot build system (LFE + Rust)$(RESET)        $(CYAN)║$(RESET)"
	@echo "$(CYAN)╚══════════════════════════════════════════════════════════╝$(RESET)"
	@echo ""
	@echo "$(GREEN)General (both languages):$(RESET)"
	@echo "  $(YELLOW)make build$(RESET)            - Compile LFE + Rust"
	@echo "  $(YELLOW)make test$(RESET)             - Test LFE + Rust"
	@echo "  $(YELLOW)make lint$(RESET)             - Lint LFE + Rust"
	@echo "  $(YELLOW)make format$(RESET)           - Format LFE + Rust"
	@echo "  $(YELLOW)make coverage$(RESET)         - Coverage for LFE + Rust"
	@echo "  $(YELLOW)make docs$(RESET)             - Docs for LFE + Rust"
	@echo "  $(YELLOW)make check$(RESET)            - Full gate: lint + test (both)"
	@echo "  $(YELLOW)make ci$(RESET)               - Alias for check"
	@echo "  $(YELLOW)make clean$(RESET)            - Clean both build trees"
	@echo "  $(YELLOW)make info$(RESET)             - Show build information"
	@echo "  $(YELLOW)make check-tools$(RESET)      - Verify required tools"
	@echo ""

# ============================================================================
# Aggregate targets — fan out to both language modules
# ============================================================================
.PHONY: build test lint format coverage docs check ci clean

build: compile-lfe build-rust
	@echo "$(GREEN)✓ Built LFE + Rust$(RESET)"

test: test-lfe test-rust
	@echo ""
	@echo "$(GREEN)✓ All tests passed (LFE + Rust)$(RESET)"
	@echo ""

lint: lint-lfe lint-rust
	@echo ""
	@echo "$(GREEN)✓ All linters passed (LFE + Rust)$(RESET)"
	@echo ""

format: format-lfe format-rust
	@echo "$(GREEN)✓ Formatted LFE + Rust$(RESET)"

coverage: coverage-lfe coverage-rust
	@echo "$(GREEN)✓ Coverage generated (LFE + Rust)$(RESET)"

docs: docs-lfe docs-rust
	@echo "$(GREEN)✓ Docs generated (LFE + Rust)$(RESET)"

check: lint test
	@echo ""
	@echo "$(GREEN)✓ All checks passed (lint + test, both languages)$(RESET)"
	@echo ""

ci: check
	@echo "$(GREEN)✓ CI gate passed$(RESET)"

clean: clean-lfe clean-rust
	@echo "$(GREEN)✓ Cleaned LFE + Rust$(RESET)"

# ============================================================================
# Information (spans both toolchains)
# ============================================================================
.PHONY: info
info:
	@echo ""
	@echo "$(CYAN)╔══════════════════════════════════════════════════════════╗$(RESET)"
	@echo "$(CYAN)║$(RESET)  $(BLUE)Build Information$(RESET)                                       $(CYAN)║$(RESET)"
	@echo "$(CYAN)╚══════════════════════════════════════════════════════════╝$(RESET)"
	@echo ""
	@echo "$(GREEN)Project:$(RESET)"
	@echo "  Name:           $(PROJECT_NAME) v$(APP_VERSION)"
	@echo "  Build Time:     $(BUILD_TIME)"
	@echo "  Workspace:      $$(pwd)"
	@echo ""
	@echo "$(GREEN)Git:$(RESET)"
	@echo "  Branch:         $(GIT_BRANCH)"
	@echo "  Commit:         $(GIT_COMMIT)"
	@echo ""
	@echo "$(GREEN)Tools:$(RESET)"
	@echo "  OTP:            $(OTP_VERSION)"
	@echo "  Rebar3:         $$($(REBAR) --version 2>/dev/null || echo 'not found')"
	@echo "  Rust:           $(RUST_VERSION)"
	@echo "  Cargo:          $$(cargo --version 2>/dev/null || echo 'not found')"
	@echo "  Clippy:         $$(cargo clippy --version 2>/dev/null || echo 'not found')"
	@echo "  Rustfmt:        $$(rustfmt --version 2>/dev/null || echo 'not found')"
	@echo ""

# ============================================================================
# Tool check (spans both toolchains)
# ============================================================================
.PHONY: check-tools
check-tools:
	@echo "$(BLUE)Checking for required tools...$(RESET)"
	@echo "$(CYAN)LFE / BEAM:$(RESET)"
	@command -v erl >/dev/null 2>&1 && echo "  $(GREEN)✓ erl found (OTP $(OTP_VERSION))$(RESET)" || echo "  $(RED)✗ erl not found$(RESET)"
	@command -v $(REBAR) >/dev/null 2>&1 && echo "  $(GREEN)✓ rebar3 found$(RESET)" || echo "  $(RED)✗ rebar3 not found$(RESET)"
	@echo "$(CYAN)Rust:$(RESET)"
	@command -v rustc >/dev/null 2>&1 && echo "  $(GREEN)✓ rustc found ($(RUST_VERSION))$(RESET)" || echo "  $(RED)✗ rustc not found$(RESET)"
	@command -v cargo >/dev/null 2>&1 && echo "  $(GREEN)✓ cargo found$(RESET)" || echo "  $(RED)✗ cargo not found$(RESET)"
	@command -v rustfmt >/dev/null 2>&1 && echo "  $(GREEN)✓ rustfmt found$(RESET)" || echo "  $(RED)✗ rustfmt not found (rustup component add rustfmt)$(RESET)"
	@cargo clippy --version >/dev/null 2>&1 && echo "  $(GREEN)✓ clippy found$(RESET)" || echo "  $(RED)✗ clippy not found (rustup component add clippy)$(RESET)"
	@command -v git >/dev/null 2>&1 && echo "  $(GREEN)✓ git found$(RESET)" || echo "  $(RED)✗ git not found$(RESET)"
	@test -f Cargo.toml && echo "  $(GREEN)✓ Cargo.toml found$(RESET)" || echo "  $(RED)✗ Cargo.toml not found$(RESET)"
