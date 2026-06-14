# ============================================================================
# mk/rust.mk — the Rust workspace side of xrepl
#
# Included by ./Makefile. Expects the shared variables it defines (colors,
# PROJECT_NAME, CODE_NAME, GIT_*). Do not run this module directly.
#
# Adapted from the Oxurack project's Makefile. Targets that would collide with
# mk/lfe.mk are suffixed `-rust`; truly Rust-only utilities keep their names.
# cargo runs from the repo root, where Cargo.toml lives.
# ============================================================================

# --- Git remotes (multi-remote push) ----------------------------------------
# NOTE: adapted to the xrepl org following the Oxurack pattern. CONFIRM these
# URLs match your actual remotes before relying on `make push` / `make remotes`.
GIT_REMOTES      := macpro github codeberg
REMOTE_macpro    := ssh://macpro.local:23231/xrepl/$(CODE_NAME).git
REMOTE_github    := git@github.com:xrepl/$(CODE_NAME).git
REMOTE_codeberg  := ssh://git@codeberg.org/xrepl/$(CODE_NAME).git

# --- crates.io publishing ---------------------------------------------------
# Dependency order: leaf crates first, dependents later.
PUBLISH_ORDER := xrepl-core xrepl-adventure xrepl
# crates.io rate-limit delay between publishes (seconds).
PUBLISH_DELAY := 372

# ----------------------------------------------------------------------------
# Help (Rust section)
# ----------------------------------------------------------------------------
.PHONY: help-rust
help-rust:
	@echo "$(GREEN)Rust (cargo workspace):$(RESET)"
	@echo "  $(YELLOW)make build-rust$(RESET)       - Build the workspace (debug)"
	@echo "  $(YELLOW)make build-release$(RESET)    - Build optimized release"
	@echo "  $(YELLOW)make test-rust$(RESET)        - Run all workspace tests"
	@echo "  $(YELLOW)make lint-rust$(RESET)        - clippy (-D warnings) + fmt check"
	@echo "  $(YELLOW)make format-rust$(RESET)      - Format with rustfmt"
	@echo "  $(YELLOW)make coverage-rust$(RESET)    - Coverage (cargo llvm-cov)"
	@echo "  $(YELLOW)make coverage-html-rust$(RESET) - HTML coverage report"
	@echo "  $(YELLOW)make docs-rust$(RESET)        - Generate Rust API docs"
	@echo "  $(YELLOW)make deps$(RESET)             - Upgrade dependencies"
	@echo "  $(YELLOW)make check-deps$(RESET)       - Check for outdated deps"
	@echo "  $(YELLOW)make clean-rust$(RESET)       - cargo clean"
	@echo "  $(YELLOW)make remotes$(RESET)          - Configure git remotes (xrepl org)"
	@echo "  $(YELLOW)make push$(RESET)             - Push current branch to all remotes"
	@echo "  $(YELLOW)make publish$(RESET)          - Publish crates to crates.io (in order)"
	@echo "  $(YELLOW)make publish-dry-run$(RESET)  - Verify crates can be packaged"
	@echo "  $(YELLOW)make publish-one CRATE=x$(RESET) - Publish a single crate"
	@echo "  $(YELLOW)make tracked-files$(RESET)    - Save list of git-tracked files"
	@echo ""

# ----------------------------------------------------------------------------
# Building
# ----------------------------------------------------------------------------
.PHONY: build-rust build-release
build-rust:
	@echo "$(BLUE)Building $(PROJECT_NAME) (Rust)...$(RESET)"
	@cargo build
	@echo "$(GREEN)✓ Rust build complete$(RESET)"

build-release:
	@echo "$(BLUE)Building $(PROJECT_NAME) (Rust, release)...$(RESET)"
	@cargo build --release
	@echo "$(GREEN)✓ Rust release build complete$(RESET)"

# ----------------------------------------------------------------------------
# Cleaning
# ----------------------------------------------------------------------------
.PHONY: clean-rust
clean-rust:
	@echo "$(BLUE)Cleaning Rust artifacts...$(RESET)"
	@cargo clean
	@echo "$(GREEN)✓ Rust clean complete$(RESET)"

# ----------------------------------------------------------------------------
# Testing & quality
# ----------------------------------------------------------------------------
.PHONY: test-rust lint-rust format-rust
test-rust:
	@echo "$(BLUE)Running Rust workspace tests...$(RESET)"
	@cargo test --all-features --workspace
	@echo "$(GREEN)✓ Rust tests passed$(RESET)"

lint-rust:
	@echo "$(BLUE)Running Rust linters...$(RESET)"
	@echo "$(CYAN)• clippy...$(RESET)"
	@cargo clippy --all-features --workspace -- -D warnings
	@echo "$(GREEN)✓ clippy passed$(RESET)"
	@echo "$(CYAN)• format check...$(RESET)"
	@cargo fmt --all -- --check
	@echo "$(GREEN)✓ format check passed$(RESET)"

format-rust:
	@echo "$(BLUE)Formatting Rust code...$(RESET)"
	@cargo fmt --all
	@echo "$(GREEN)✓ Rust code formatted$(RESET)"

# ----------------------------------------------------------------------------
# Coverage
# ----------------------------------------------------------------------------
.PHONY: coverage-rust coverage-html-rust
coverage-rust:
	@echo "$(BLUE)Generating Rust coverage...$(RESET)"
	@cargo llvm-cov --workspace --all-features
	@echo "$(GREEN)✓ Rust coverage generated$(RESET)"
	@echo "$(YELLOW)→ For an HTML report, run: make coverage-html-rust$(RESET)"

coverage-html-rust:
	@echo "$(BLUE)Generating HTML coverage report...$(RESET)"
	@cargo llvm-cov --html --workspace --all-features
	@echo "$(GREEN)✓ HTML coverage report generated$(RESET)"
	@echo "$(CYAN)→ Report: target/llvm-cov/html/index.html$(RESET)"

# ----------------------------------------------------------------------------
# Documentation
# ----------------------------------------------------------------------------
docs-rust: DOCS_PATH = target/doc/$(CODE_NAME)
docs-rust:
	@echo "$(BLUE)Generating Rust API docs...$(RESET)"
	@cargo doc --all-features --no-deps --workspace
	@echo ""
	@echo "Docs are available here:"
	@echo " * $(DOCS_PATH)"
	@echo " * file://$(shell pwd)/$(DOCS_PATH)/index.html"
	@echo ""

# ----------------------------------------------------------------------------
# Dependency management (auto-installs cargo tooling on demand)
# ----------------------------------------------------------------------------
.PHONY: ensure-binstall check-deps deps
ensure-binstall:
	@command -v cargo-binstall >/dev/null 2>&1 || { \
		echo "$(YELLOW)→ Installing cargo-binstall...$(RESET)"; \
		curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash; \
	}

check-deps: ensure-binstall
	@echo "$(BLUE)Checking for outdated dependencies...$(RESET)"
	@command -v cargo-outdated >/dev/null 2>&1 || { \
		echo "$(YELLOW)→ Installing cargo-outdated...$(RESET)"; \
		cargo binstall -y cargo-outdated; \
	}
	@OUTPUT=$$(cargo outdated --root-deps-only --ignore-external-rel 2>/dev/null); \
	echo "$$OUTPUT"; \
	echo ""; \
	if echo "$$OUTPUT" | grep -E "^[a-z0-9_-]+\s+" | grep -v "^----" | awk '{print $$3}' | grep -v "^---$$" | grep -v "^Compat$$" | grep -E "^[0-9]" | grep -q .; then \
		echo "$(RED)✗ Compatible dependency updates available$(RESET)"; \
		echo "$(YELLOW)→ Run 'make deps' to update and commit the updated Cargo.lock$(RESET)"; \
		exit 1; \
	else \
		echo "$(GREEN)✓ All dependencies up to date$(RESET)"; \
	fi

deps: ensure-binstall
	@echo "$(BLUE)Updating dependencies...$(RESET)"
	@command -v cargo-upgrade >/dev/null 2>&1 || { \
		echo "$(YELLOW)→ Installing cargo-edit...$(RESET)"; \
		cargo binstall -y cargo-edit; \
	}
	@cargo upgrade
	@echo "$(GREEN)✓ Cargo deps upgraded$(RESET)"

# ----------------------------------------------------------------------------
# Git remotes & push
# ----------------------------------------------------------------------------
.PHONY: remotes push
remotes:
	@echo "$(BLUE)Configuring git remotes...$(RESET)"
	@for remote in $(GIT_REMOTES); do \
		case $$remote in \
			macpro)   url="$(REMOTE_macpro)"   ;; \
			github)   url="$(REMOTE_github)"   ;; \
			codeberg) url="$(REMOTE_codeberg)" ;; \
		esac; \
		if git remote get-url $$remote >/dev/null 2>&1; then \
			echo "  $(YELLOW)⊙$(RESET) $$remote already exists ($$url)"; \
		else \
			git remote add $$remote $$url; \
			echo "  $(GREEN)✓$(RESET) Added $$remote → $$url"; \
		fi; \
	done
	@echo "$(GREEN)✓ Remotes configured$(RESET)"

# Pushes the *current* branch (and tags) to every remote.
push:
	@echo "$(BLUE)Pushing $(GIT_BRANCH) to all remotes...$(RESET)"
	@for remote in $(GIT_REMOTES); do \
		echo "$(CYAN)• $$remote:$(RESET)"; \
		git push $$remote $(GIT_BRANCH) && git push $$remote --tags; \
		echo "$(GREEN)✓ Pushed$(RESET)"; \
	done

# ----------------------------------------------------------------------------
# crates.io publishing
# ----------------------------------------------------------------------------
.PHONY: publish publish-dry-run publish-one
publish:
	@echo ""
	@echo "$(CYAN)╔══════════════════════════════════════════════════════════╗$(RESET)"
	@echo "$(CYAN)║$(RESET) $(BLUE)Publishing $(PROJECT_NAME) crates to crates.io$(RESET)                   $(CYAN)║$(RESET)"
	@echo "$(CYAN)╚══════════════════════════════════════════════════════════╝$(RESET)"
	@echo ""
	@echo "$(YELLOW)⚠ This publishes all crates in dependency order$(RESET)"
	@echo "$(YELLOW)⚠ Ensure tests pass and versions are bumped from 0.0.0$(RESET)"
	@echo ""
	@read -p "Continue? [y/N] " -n 1 -r; \
	echo; \
	if [[ ! $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "$(RED)✗ Aborted$(RESET)"; \
		exit 1; \
	fi
	@echo ""
	@echo "$(BLUE)Publishing crates in dependency order...$(RESET)"
	@for crate in $(PUBLISH_ORDER); do \
		echo ""; \
		echo "$(CYAN)• Publishing $$crate...$(RESET)"; \
		output=$$(cargo publish -p $$crate 2>&1); \
		result=$$?; \
		if [ $$result -eq 0 ]; then \
			echo "  $(GREEN)✓$(RESET) $$crate published"; \
			echo "  $(YELLOW)→ Waiting for crates.io rate limit + index update...$(RESET)"; \
			sleep $(PUBLISH_DELAY); \
		elif echo "$$output" | grep -q "already exists"; then \
			echo "  $(YELLOW)⊙$(RESET) $$crate already published, skipping"; \
		elif echo "$$output" | grep -q "429 Too Many Requests"; then \
			echo "  $(YELLOW)⚠$(RESET) Rate limit hit for $$crate"; \
			echo "  $(YELLOW)→$(RESET) Wait, then: cargo publish -p $$crate"; \
			exit 1; \
		else \
			echo "  $(RED)✗$(RESET) Failed to publish $$crate"; \
			echo "$$output"; \
			exit 1; \
		fi; \
	done
	@echo ""
	@echo "$(GREEN)✓ All crates published$(RESET)"
	@echo ""

# NOTE: uses `--allow-dirty` only to *list* package contents (read-only); the
# real `publish` target above does NOT bypass cargo's clean-tree gate. Kept per
# the Oxurack original — flag it if you'd rather the dry run also require a
# clean tree.
publish-dry-run:
	@echo ""
	@echo "$(BLUE)Dry run — verifying each crate can be packaged:$(RESET)"
	@i=1; for crate in $(PUBLISH_ORDER); do \
		echo "  $(YELLOW)$$i.$(RESET) $$crate"; i=$$((i+1)); \
	done
	@echo ""
	@for crate in $(PUBLISH_ORDER); do \
		echo "$(CYAN)• Packaging $$crate...$(RESET)"; \
		if cargo package -p $$crate --allow-dirty --list > /dev/null 2>&1; then \
			echo "  $(GREEN)✓$(RESET) $$crate is ready"; \
		else \
			echo "  $(RED)✗$(RESET) $$crate failed validation"; \
			cargo package -p $$crate --allow-dirty --list; \
			exit 1; \
		fi; \
	done
	@echo ""
	@echo "$(GREEN)✓ All crates ready for publishing$(RESET)"
	@echo "$(CYAN)→ 'make publish' to publish, or 'make publish-one CRATE=name'$(RESET)"
	@echo ""

publish-one:
	@if [ -z "$(CRATE)" ]; then \
		echo "$(RED)Error: CRATE not set$(RESET)"; \
		echo "Usage: make publish-one CRATE=xrepl-core"; \
		exit 1; \
	fi
	@echo "$(CYAN)Publishing $(CRATE)...$(RESET)"
	@cargo publish -p $(CRATE)
	@echo "$(GREEN)✓ Published $(CRATE)$(RESET)"

# ----------------------------------------------------------------------------
# Utilities
# ----------------------------------------------------------------------------
.PHONY: tracked-files
tracked-files:
	@echo "$(BLUE)Saving tracked files list...$(RESET)"
	@mkdir -p ./target
	@git ls-files > ./target/git-tracked-files.txt
	@echo "$(GREEN)✓ Saved to ./target/git-tracked-files.txt$(RESET)"
	@echo "$(CYAN)• Total files: $$(wc -l < ./target/git-tracked-files.txt)$(RESET)"
