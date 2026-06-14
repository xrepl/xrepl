# ============================================================================
# mk/lfe.mk — the LFE / BEAM side of xrepl
#
# Included by ./Makefile. Expects the shared variables it defines (colors,
# PROJECT_NAME, REBAR, OTP_VERSION, GIT_*). Do not run this module directly.
#
# Scope: LFE/OTP only. The Rust the original (typed project) version carried
# now lives in mk/rust.mk; the typed-specific `golden-*` oracle targets were
# dropped (they referenced scripts/expand-oracle + test/golden/, which this
# repo does not have).
#
# All targets are suffixed `-lfe` so they compose with mk/rust.mk under the
# aggregate targets in ./Makefile.
# ============================================================================

# ----------------------------------------------------------------------------
# Help (LFE section)
# ----------------------------------------------------------------------------
.PHONY: help-lfe
help-lfe:
	@echo "$(GREEN)LFE / BEAM (rebar3):$(RESET)"
	@echo "  $(YELLOW)make compile-lfe$(RESET)      - Compile the LFE/OTP app"
	@echo "  $(YELLOW)make test-lfe$(RESET)         - Run eunit + Common Test"
	@echo "  $(YELLOW)make test-unit-lfe$(RESET)    - Run eunit only"
	@echo "  $(YELLOW)make test-ct-lfe$(RESET)      - Run Common Test only"
	@echo "  $(YELLOW)make test-proper-lfe$(RESET)  - Run PropEr property tests"
	@echo "  $(YELLOW)make lint-lfe$(RESET)         - Run xref"
	@echo "  $(YELLOW)make xref-lfe$(RESET)         - Run xref only"
	@echo "  $(YELLOW)make dialyzer-lfe$(RESET)     - Run dialyzer (often noisy on LFE)"
	@echo "  $(YELLOW)make coverage-lfe$(RESET)     - Coverage (proper + cover)"
	@echo "  $(YELLOW)make docs-lfe$(RESET)         - Generate ex_doc documentation"
	@echo "  $(YELLOW)make format-lfe$(RESET)       - Format LFE sources"
	@echo "  $(YELLOW)make repl-lfe$(RESET)         - Start an LFE REPL in the project"
	@echo "  $(YELLOW)make clean-lfe$(RESET)        - Clean BEAM build artifacts"
	@echo "  $(YELLOW)make distclean-lfe$(RESET)    - Deep clean (remove _build)"
	@echo ""

# ----------------------------------------------------------------------------
# Building
# ----------------------------------------------------------------------------
.PHONY: compile-lfe
compile-lfe:
	@echo "$(BLUE)Compiling LFE/OTP app...$(RESET)"
	@$(REBAR) compile
	@echo "$(GREEN)✓ LFE compiled$(RESET)"

# ----------------------------------------------------------------------------
# Testing
# ----------------------------------------------------------------------------
.PHONY: test-lfe test-unit-lfe test-ct-lfe test-proper-lfe
test-lfe:
	@echo "$(BLUE)Running LFE tests (eunit + ct)...$(RESET)"
	@$(REBAR) do eunit, ct
	@echo "$(GREEN)✓ LFE tests passed$(RESET)"

test-unit-lfe:
	@echo "$(BLUE)Running eunit...$(RESET)"
	@$(REBAR) eunit

test-ct-lfe:
	@echo "$(BLUE)Running Common Test...$(RESET)"
	@$(REBAR) ct

test-proper-lfe:
	@echo "$(BLUE)Running PropEr property tests...$(RESET)"
	@$(REBAR) proper

# ----------------------------------------------------------------------------
# Quality / linting
# ----------------------------------------------------------------------------
.PHONY: lint-lfe xref-lfe dialyzer-lfe
lint-lfe: xref-lfe
	@echo "$(GREEN)✓ LFE lint passed$(RESET)"

xref-lfe:
	@echo "$(BLUE)Running xref...$(RESET)"
	@$(REBAR) xref
	@echo "$(GREEN)✓ xref passed$(RESET)"

# Dialyzer is kept available but out of the default lint gate: it is unreliable
# on LFE (macro/include expansion confuses its analysis), so a failure here is
# not necessarily a real defect. Run it deliberately.
dialyzer-lfe:
	@echo "$(BLUE)Running dialyzer (note: often noisy on LFE)...$(RESET)"
	@$(REBAR) dialyzer

# ----------------------------------------------------------------------------
# Coverage
# ----------------------------------------------------------------------------
.PHONY: coverage-lfe
coverage-lfe:
	@echo "$(BLUE)Generating LFE coverage...$(RESET)"
	@$(REBAR) coverage
	@echo "$(GREEN)✓ LFE coverage generated$(RESET)"

# ----------------------------------------------------------------------------
# Documentation
# ----------------------------------------------------------------------------
.PHONY: docs-lfe
docs-lfe:
	@echo "$(BLUE)Generating LFE documentation...$(RESET)"
	@$(REBAR) ex_doc 2>/dev/null || echo "$(YELLOW)→ ex_doc not configured; skipping$(RESET)"
	@echo "$(GREEN)✓ LFE docs step complete$(RESET)"

# ----------------------------------------------------------------------------
# Formatting
# ----------------------------------------------------------------------------
.PHONY: format-lfe
format-lfe:
	@echo "$(BLUE)Formatting LFE sources...$(RESET)"
	@$(REBAR) lfe format 2>/dev/null || echo "$(YELLOW)→ no LFE formatter available (rebar3_lfe format); skipping$(RESET)"

# ----------------------------------------------------------------------------
# REPL
# ----------------------------------------------------------------------------
.PHONY: repl-lfe
repl-lfe:
	@$(REBAR) lfe repl

# ----------------------------------------------------------------------------
# Cleaning
# ----------------------------------------------------------------------------
.PHONY: clean-lfe distclean-lfe
clean-lfe:
	@echo "$(BLUE)Cleaning BEAM artifacts...$(RESET)"
	@$(REBAR) clean
	@rm -rf logs erl_crash.dump doc test/*.beam src/*.beam ebin
	@echo "$(GREEN)✓ LFE clean complete$(RESET)"

distclean-lfe: clean-lfe
	@rm -rf _build
	@echo "$(GREEN)✓ LFE deep clean complete (_build removed)$(RESET)"
