# Root Makefile — run all unit tests from repo root
.PHONY: test test-api help

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "  test      Run all unit tests (backend Go + frontend Flutter)"
	@echo "  test-api  Run all unit tests + API smoke test (backend must be running)"
	@echo ""

test: ## Run all unit tests (backend + frontend)
	@./run_all_tests.sh

test-api: ## Run all unit tests and API smoke test
	@./run_all_tests.sh --api
