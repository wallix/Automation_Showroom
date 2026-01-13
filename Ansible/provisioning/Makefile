.PHONY: help deps lint auth provision provision-full demo demo-quick enterprise enterprise-quick cleanup cleanup-demo cleanup-enterprise cleanup-dry-run ops-health test-collection clean

SHELL := /bin/bash
PYTHON := python3
ANSIBLE := ansible-playbook
INVENTORY_DEV ?= inventories/dev/hosts.ini
INVENTORY_TEST ?= inventories/test/hosts.ini
INVENTORY_PROD ?= inventories/prod/hosts.ini
CURRENT_INVENTORY ?= $(INVENTORY_DEV)
VAULT_FILE ?= /tmp/.vault_pass
BASTION_HOST ?= 10.10.122.15
VERBOSITY ?= -v

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m

help:
	@echo "╔══════════════════════════════════════════════════════════════╗"
	@echo "║         WALLIX Ansible Provisioning - Makefile               ║"
	@echo "╠══════════════════════════════════════════════════════════════╣"
	@echo "║  SETUP                                                       ║"
	@echo "║    make deps              Install Python dependencies        ║"
	@echo "║    make lint              Run ansible-lint and yamllint      ║"
	@echo "║                                                              ║"
	@echo "║  AUTHENTICATION                                              ║"
	@echo "║    make auth              Test authentication to bastion     ║"
	@echo "║                                                              ║"
	@echo "║  PROVISIONING                                                ║"
	@echo "║    make provision         Full provisioning (interactive)    ║"
	@echo "║    make provision-full    Full provisioning (no confirm)     ║"
	@echo "║    make demo              Demo provisioning (interactive)    ║"
	@echo "║    make demo-quick        Demo provisioning (no confirm)     ║"
	@echo "║    make enterprise        Enterprise scale provisioning      ║"
	@echo "║    make enterprise-quick  Enterprise provisioning (no conf)  ║"
	@echo "║                                                              ║"
	@echo "║  CLEANUP                                                     ║"
	@echo "║    make cleanup           Interactive cleanup                ║"
	@echo "║    make cleanup-demo      Cleanup demo resources only        ║"
	@echo "║    make cleanup-enterprise Cleanup enterprise resources      ║"
	@echo "║    make cleanup-dry-run   Preview cleanup (no changes)       ║"
	@echo "║                                                              ║"
	@echo "║  OPERATIONAL                                                 ║"
	@echo "║    make ops-health        Run health checks                  ║"
	@echo "║    make test-collection   Test collection roles (read-only)  ║"
	@echo "║                                                              ║"
	@echo "║  MAINTENANCE                                                 ║"
	@echo "║    make clean             Remove caches and temp files       ║"
	@echo "╚══════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "Environment variables:"
	@echo "  CURRENT_INVENTORY = $(CURRENT_INVENTORY)"
	@echo "  BASTION_HOST      = $(BASTION_HOST)"
	@echo "  VAULT_FILE        = $(VAULT_FILE)"
	@echo "  VERBOSITY         = $(VERBOSITY)"
	@echo ""
	@echo "Examples:"
	@echo "  make demo BASTION_HOST=192.168.1.75"
	@echo "  make provision CURRENT_INVENTORY=inventories/prod/hosts.ini"
	@echo "  make cleanup-dry-run BASTION_HOST=10.10.122.15"

# =============================================================================
# SETUP
# =============================================================================

deps:
	@echo "$(GREEN)Installing Python dependencies...$(NC)"
	$(PYTHON) -m pip install -q ansible jinja2 pyyaml requests
	@echo "$(GREEN)✓ Dependencies installed$(NC)"

lint:
	@echo "$(GREEN)Running linters...$(NC)"
	@ansible-lint playbooks/ 2>/dev/null || true
	@yamllint inventories/ vars/ 2>/dev/null || true
	@echo "$(GREEN)✓ Linting complete$(NC)"

# =============================================================================
# AUTHENTICATION
# =============================================================================

auth: lint
	@echo "$(GREEN)Testing authentication to $(BASTION_HOST)...$(NC)"
	$(ANSIBLE) playbooks/test-auth.yml -i $(CURRENT_INVENTORY) \
		-e wallix_bastion_host=$(BASTION_HOST) \
		--vault-password-file $(VAULT_FILE) $(VERBOSITY)

# =============================================================================
# PROVISIONING
# =============================================================================

provision: lint
	@echo "$(YELLOW)⚠️  Full provisioning against $(BASTION_HOST)$(NC)"
	@read -p "Continue? [y/N] " -n 1 -r; echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		$(ANSIBLE) playbooks/provision-full.yml -i $(CURRENT_INVENTORY) \
			-e wallix_bastion_host=$(BASTION_HOST) \
			--vault-password-file $(VAULT_FILE) $(VERBOSITY); \
	else \
		echo "$(RED)Aborted.$(NC)"; \
	fi

provision-full:
	@echo "$(GREEN)Running full provisioning...$(NC)"
	$(ANSIBLE) playbooks/provision-full.yml -i $(CURRENT_INVENTORY) \
		-e wallix_bastion_host=$(BASTION_HOST) \
		--vault-password-file $(VAULT_FILE) $(VERBOSITY)

demo: lint
	@echo "$(GREEN)Running demo provisioning (interactive)...$(NC)"
	$(ANSIBLE) playbooks/demo-provision.yml -i $(CURRENT_INVENTORY) \
		-e wallix_bastion_host=$(BASTION_HOST) \
		--vault-password-file $(VAULT_FILE) $(VERBOSITY)

demo-quick:
	@echo "$(GREEN)Running demo provisioning (no confirmation)...$(NC)"
	$(ANSIBLE) playbooks/demo-provision.yml -i $(CURRENT_INVENTORY) \
		-e wallix_bastion_host=$(BASTION_HOST) \
		-e skip_confirmation=true \
		--vault-password-file $(VAULT_FILE) $(VERBOSITY)

enterprise: lint
	@echo "$(YELLOW)⚠️  Enterprise provisioning against $(BASTION_HOST)$(NC)"
	@echo "    This will provision 45+ devices, 40+ users, 30+ authorizations"
	@read -p "Continue? [y/N] " -n 1 -r; echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		$(ANSIBLE) playbooks/enterprise-provision.yml -i $(CURRENT_INVENTORY) \
			-e wallix_bastion_host=$(BASTION_HOST) \
			--vault-password-file $(VAULT_FILE) $(VERBOSITY); \
	else \
		echo "$(RED)Aborted.$(NC)"; \
	fi

enterprise-quick:
	@echo "$(GREEN)Running enterprise provisioning (no confirmation)...$(NC)"
	$(ANSIBLE) playbooks/enterprise-provision.yml -i $(CURRENT_INVENTORY) \
		-e wallix_bastion_host=$(BASTION_HOST) \
		-e skip_confirmation=true \
		--vault-password-file $(VAULT_FILE) $(VERBOSITY)

# =============================================================================
# CLEANUP
# =============================================================================

cleanup: lint
	@echo "$(YELLOW)⚠️  Cleanup mode (interactive)$(NC)"
	$(ANSIBLE) playbooks/operational/cleanup.yml -i $(CURRENT_INVENTORY) \
		-e wallix_bastion_host=$(BASTION_HOST) \
		-e cleanup_mode=execute \
		--vault-password-file $(VAULT_FILE) $(VERBOSITY)

cleanup-demo: lint
	@echo "$(YELLOW)⚠️  Cleaning demo resources only...$(NC)"
	$(ANSIBLE) playbooks/operational/cleanup.yml -i $(CURRENT_INVENTORY) \
		-e wallix_bastion_host=$(BASTION_HOST) \
		-e cleanup_mode=execute \
		-e '{"wallix_cleanup": {"operation_mode": "execute", "require_confirmation": false}, "wallix_cleanup_safety": {"require_explicit_confirmation": false}}' \
		-e @vars/data/demo/cleanup_patterns.yml \
		--vault-password-file $(VAULT_FILE) $(VERBOSITY)

cleanup-enterprise: lint
	@echo "$(YELLOW)⚠️  Cleaning enterprise resources...$(NC)"
	@read -p "This will remove ALL enterprise resources. Continue? [y/N] " -n 1 -r; echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		$(ANSIBLE) playbooks/operational/cleanup.yml -i $(CURRENT_INVENTORY) \
			-e wallix_bastion_host=$(BASTION_HOST) \
			-e cleanup_mode=execute \
			-e '{"wallix_cleanup": {"operation_mode": "execute", "require_confirmation": false}, "wallix_cleanup_safety": {"require_explicit_confirmation": false}}' \
			-e @vars/data/enterprise/cleanup_patterns.yml \
			--vault-password-file $(VAULT_FILE) $(VERBOSITY); \
	else \
		echo "$(RED)Aborted.$(NC)"; \
	fi

cleanup-dry-run: lint
	@echo "$(GREEN)Running cleanup dry-run (no changes)...$(NC)"
	$(ANSIBLE) playbooks/operational/cleanup.yml -i $(CURRENT_INVENTORY) \
		-e wallix_bastion_host=$(BASTION_HOST) \
		-e cleanup_mode=dry-run \
		--vault-password-file $(VAULT_FILE) $(VERBOSITY)

# =============================================================================
# OPERATIONAL
# =============================================================================

ops-health:
	@echo "$(GREEN)Running health checks...$(NC)"
	$(ANSIBLE) playbooks/operational/health-check.yml -i $(CURRENT_INVENTORY) \
		-e wallix_bastion_host=$(BASTION_HOST) \
		--vault-password-file $(VAULT_FILE) $(VERBOSITY)

test-collection: lint
	@echo "$(GREEN)Running collection tests (read-only)...$(NC)"
	$(ANSIBLE) playbooks/operational/test-collection-readonly.yml -i $(CURRENT_INVENTORY) \
		-e wallix_bastion_host=$(BASTION_HOST) \
		--vault-password-file $(VAULT_FILE) $(VERBOSITY)

# =============================================================================
# MAINTENANCE
# =============================================================================

clean:
	@echo "$(GREEN)Cleaning up...$(NC)"
	@find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.retry" -delete 2>/dev/null || true
	@find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@rm -f .wallix_session* /tmp/.wallix_session* 2>/dev/null || true
	@rm -rf /tmp/wallix_backup_* /tmp/wallix_cleanup_* 2>/dev/null || true
	@echo "$(GREEN)✓ Cleanup complete$(NC)"

.DEFAULT_GOAL := help
