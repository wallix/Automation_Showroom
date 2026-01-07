.PHONY: help deps lint auth provision ops-health clean

SHELL := /bin/bash
PYTHON := python3
ANSIBLE := ansible-playbook
INVENTORY_DEV ?= inventories/dev/hosts.ini
INVENTORY_TEST ?= inventories/test/hosts.ini
INVENTORY_PROD ?= inventories/prod/hosts.ini
CURRENT_INVENTORY ?= $(INVENTORY_TEST)
VERBOSITY ?= -v

help:
	@echo "Ansible Provisioning - Available Targets"
	@echo "========================================="
	@echo "  make deps           - Install Python dependencies (ansible, jinja2, etc.)"
	@echo "  make lint           - Run ansible-lint and yamllint"
	@echo "  make auth           - Test authentication against target bastion(s)"
	@echo "  make provision      - Run full provisioning (use CURRENT_INVENTORY=inventories/prod/hosts.ini for prod)"
	@echo "  make ops-health     - Run operational health check playbook"
	@echo "  make clean          - Remove caches, temp files, logs"
	@echo ""
	@echo "Environment variables:"
	@echo "  CURRENT_INVENTORY   - Target inventory (default: $(CURRENT_INVENTORY))"
	@echo "  VERBOSITY           - Ansible verbosity (default: $(VERBOSITY))"
	@echo ""
	@echo "Quick start (test environment):"
	@echo "  make deps && make lint && make auth && make provision"
	@echo ""

deps:
	@echo "Installing Python dependencies..."
	$(PYTHON) -m pip install -q ansible jinja2 pyyaml requests
	@echo "✓ Dependencies installed"

lint:
	@echo "Running ansible-lint..."
	@ansible-lint playbooks/ roles/ 2>/dev/null || true
	@echo "Running yamllint..."
	@yamllint inventories/ vars/ 2>/dev/null || true
	@echo "✓ Linting complete"

auth: lint
	@echo "Testing authentication to bastions in $(CURRENT_INVENTORY)..."
	$(ANSIBLE) playbooks/test-auth.yml -i $(CURRENT_INVENTORY) $(VERBOSITY)

provision: lint
	@echo "Running provisioning against $(CURRENT_INVENTORY)..."
	@echo "⚠️  This will make real API calls to the bastion(s)"
	@read -p "Continue? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		$(ANSIBLE) playbooks/provision-full.yml -i $(CURRENT_INVENTORY) $(VERBOSITY); \
	else \
		echo "Aborted."; \
	fi

ops-health:
	@echo "Running operational health checks..."
	$(ANSIBLE) playbooks/operational/health-check.yml -i $(CURRENT_INVENTORY) $(VERBOSITY)

clean:
	@echo "Cleaning up..."
	@find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.retry" -delete
	@find . -type f -name "*.pyc" -delete
	@rm -f .wallix_session* /tmp/.wallix_session* 2>/dev/null || true
	@echo "✓ Cleanup complete"

.DEFAULT_GOAL := help
